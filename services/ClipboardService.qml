pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property var history: []
    property string lastText: ""

    function detectType(text: string): string {
        const trimmed = text.trim();
        if (/^https?:\/\/[^\s]+$/i.test(trimmed)) {
            return "url";
        }
        if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/i.test(trimmed)) {
            return "color";
        }
        if (/[\{\}\;\[\]\=\>\<\(\)]/.test(trimmed) && (
            /^(import|export|const|let|var|function|class|def|for|while|return|if|else|package|func|public|private)\b/.test(trimmed) ||
            /\n/.test(trimmed) ||
            /^(sudo|pacman|yay|git|cd|ls|mkdir|rm|chmod|chown|systemctl|hyprctl|qs)\b/.test(trimmed)
        )) {
            return "code";
        }
        return "text";
    }

    function formatTime(timestamp: var): string {
        const diff = Math.floor((Date.now() - timestamp) / 1000);
        if (diff < 60) return I18n.t("time.just_now");
        if (diff < 3600) return I18n.t("time.mins_ago", { n: Math.floor(diff / 60) });
        if (diff < 86400) return I18n.t("time.hours_ago", { n: Math.floor(diff / 3600) });
        return I18n.t("time.days_ago", { n: Math.floor(diff / 86400) });
    }

    function addText(text: string): void {
        if (!text || text.trim().length === 0) return;
        if (text === lastText) return;

        lastText = text;
        const type = detectType(text);
        const len = text.length;
        const lines = (text.match(/\n/g) || []).length + 1;
        const words = len > 30000 ? Math.round(len / 6) : (text.trim().match(/\S+/g) || []).length;
        const chars = len;

        const newItem = {
            text: text,
            preview: len > 80 ? text.substring(0, 80).replace(/\s+/g, " ") + "..." : text.replace(/\s+/g, " "),
            type: type,
            colorHex: type === "color" ? text.trim() : "",
            timestamp: Date.now(),
            lines: lines,
            words: words,
            chars: chars
        };

        // Remove if duplicate text exists elsewhere in history
        const filtered = history.filter(item => item.text !== text);
        filtered.unshift(newItem);

        // Keep maximum 60 items
        history = filtered.slice(0, 60);
    }

    function copyItem(item: var): void {
        if (!item || !item.text) return;
        Quickshell.execDetached(["wl-copy", "--", item.text]);
        // Re-order to top
        addText(item.text);
    }

    function deleteItem(index: int): void {
        if (index >= 0 && index < history.length) {
            const list = [...history];
            list.splice(index, 1);
            history = list;
        }
    }

    function clearAll(): void {
        history = [];
        lastText = "";
    }

    // Background poller using wl-paste
    Process {
        id: pasteWatcher
        command: ["wl-paste", "--no-newline"]

        stdout: SplitParser {
            splitMarker: "\0"
            onRead: data => {
                if (data && data.length > 0) {
                    root.addText(data);
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!pasteWatcher.running) {
                pasteWatcher.running = true;
            }
        }
    }
}
