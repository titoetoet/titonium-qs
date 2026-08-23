pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../config"

Singleton {
    id: root

    property bool visible: false
    property var activeScreen: null
    property int searchMode: 0 // 0: All, 1: Clipboard, 2: Files
    property string query: ""
    property int selectedIndex: 0
    property var results: []
    property var cachedApps: []

    GlobalShortcut {
        name: "spotlight"
        onPressed: root.toggle()
    }

    function cycleMode(): void {
        searchMode = (searchMode + 1) % 3;
        selectedIndex = 0;
        updateResults();
    }

    function setMode(mode: int): void {
        searchMode = mode;
        selectedIndex = 0;
        updateResults();
    }

    function getFocusedScreen(): var {
        const focusedMon = Hyprland.focusedMonitor;
        if (!focusedMon) return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const s = Quickshell.screens[i];
            if (s.name === focusedMon.name) {
                return s;
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function open(): void {
        query = "";
        selectedIndex = 0;
        activeScreen = getFocusedScreen();
        if (cachedApps.length === 0) {
            refreshAppsCache();
        }
        updateResults();
        visible = true;
    }

    function openClipboard(): void {
        searchMode = 1;
        query = "";
        selectedIndex = 0;
        activeScreen = getFocusedScreen();
        updateResults();
        visible = true;
    }

    function close(): void {
        visible = false;
        query = "";
        selectedIndex = 0;
        searchMode = 0;
        activeScreen = null;
    }

    function toggle(): void {
        if (visible) {
            close();
        } else {
            open();
        }
    }

    function selectNext(): void {
        if (results.length > 0) {
            selectedIndex = (selectedIndex + 1) % results.length;
        }
    }

    function selectPrevious(): void {
        if (results.length > 0) {
            selectedIndex = (selectedIndex - 1 + results.length) % results.length;
        }
    }

    function executeSelected(): void {
        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
            executeItem(results[selectedIndex]);
        }
    }

    function executeItem(item: var): void {
        if (!item) return;

        if (item.type === "clipboard" && item.clipItem) {
            ClipboardService.copyItem(item.clipItem);
            close();
            return;
        }

        if (item.type === "file" && item.path) {
            Quickshell.execDetached(["sh", "-c", "xdg-open " + item.path + " >/dev/null 2>&1 || thunar " + item.path]);
            close();
            return;
        }

        if (item.type === "calc") {
            Quickshell.execDetached(["wl-copy", String(item.value)]);
            close();
            return;
        }

        if (item.type === "system") {
            if (item.action === "shutdown") {
                Quickshell.execDetached(["systemctl", "poweroff"]);
            } else if (item.action === "reboot") {
                Quickshell.execDetached(["systemctl", "reboot"]);
            } else if (item.action === "lock") {
                Quickshell.execDetached(["sh", "-c", "command -v hyprlock >/dev/null 2>&1 && hyprlock || swaylock"]);
            } else if (item.action === "suspend") {
                Quickshell.execDetached(["systemctl", "suspend"]);
            } else if (item.action === "logout") {
                Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
            } else if (item.action === "terminal") {
                Quickshell.execDetached(["sh", "-c", "command -v kitty >/dev/null 2>&1 && kitty || command -v alacritty >/dev/null 2>&1 && alacritty || xterm"]);
            }
            close();
            return;
        }

        if (item.type === "app" && item.entry) {
            let executed = false;
            try {
                if (typeof item.entry.execute === "function") {
                    item.entry.execute();
                    executed = true;
                } else if (typeof item.entry.launch === "function") {
                    item.entry.launch();
                    executed = true;
                }
            } catch (e) {
                executed = false;
            }

            if (!executed) {
                const rawCmd = item.entry.execString || item.entry.exec || "";
                if (rawCmd.length > 0) {
                    const cleanCmd = rawCmd.replace(/%[fFuUdDnNickvm]/g, "").trim();
                    Quickshell.execDetached(["sh", "-c", cleanCmd]);
                } else if (Array.isArray(item.entry.command) && item.entry.command.length > 0) {
                    Quickshell.execDetached(item.entry.command);
                }
            }
            close();
            return;
        }
    }

    function evaluateMath(expr: string): var {
        const clean = expr.trim();
        // Check if string is a valid math formula
        if (!/^[\d\s\+\-\*\/\^\%\(\)\.\,\e\E]+$/.test(clean) && !clean.startsWith("sqrt") && !clean.startsWith("sin") && !clean.startsWith("cos")) {
            return null;
        }
        // Must contain at least one digit and one operator or function
        if (!/\d/.test(clean) || !/[\+\-\*\/\^\%\(]/.test(clean)) {
            return null;
        }

        try {
            const sanitized = clean
                .replace(/\^/g, "**")
                .replace(/sqrt\(([^)]+)\)/g, "Math.sqrt($1)")
                .replace(/sin\(([^)]+)\)/g, "Math.sin($1)")
                .replace(/cos\(([^)]+)\)/g, "Math.cos($1)")
                .replace(/pi/gi, "Math.PI");

            const fn = new Function("return (" + sanitized + ");");
            const res = fn();
            if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
                // Format nicely
                const formatted = Number.isInteger(res) ? String(res) : res.toFixed(4).replace(/\.?0+$/, "");
                return {
                    type: "calc",
                    title: formatted,
                    subtitle: clean + " = " + formatted + "  •  Press Enter to copy",
                    icon: "calculate",
                    value: formatted
                };
            }
        } catch (e) {
            return null;
        }
        return null;
    }

    function refreshAppsCache(): void {
        const raw = DesktopEntries.applications.values || [];
        const list = [];
        for (let i = 0; i < raw.length; i++) {
            const app = raw[i];
            if (!app || !app.name || app.noDisplay) continue;
            list.push({
                name: app.name,
                nameLower: (app.name || "").toLowerCase(),
                genericLower: (app.genericName || "").toLowerCase(),
                commentLower: (app.comment || "").toLowerCase(),
                execLower: (app.execString || app.exec || "").toLowerCase(),
                idLower: (app.id || "").toLowerCase(),
                startupClassLower: (app.startupClass || "").toLowerCase(),
                subtitle: app.genericName || app.comment || "Application",
                category: (app.categories && app.categories.length > 0) ? app.categories[0] : "App",
                icon: app.icon || "application-x-executable",
                entry: app
            });
        }
        root.cachedApps = list;
    }

    Component.onCompleted: refreshAppsCache()

    function updateResults(): void {
        const q = query.trim().toLowerCase();
        const list = [];

        // ── MODE 1: CLIPBOARD HISTORY ─────────────────────────────────────────
        if (searchMode === 1) {
            const history = ClipboardService.history || [];
            for (let i = 0; i < history.length; i++) {
                const item = history[i];
                if (!item || !item.text) continue;

                if (q.length === 0 || item.text.toLowerCase().includes(q)) {
                    list.push({
                        type: "clipboard",
                        title: item.preview,
                        subtitle: ClipboardService.formatTime(item.timestamp) + " • " + item.chars + " chars" + (item.lines > 1 ? " • " + item.lines + " lines" : ""),
                        icon: item.type === "url" ? "link" : item.type === "code" ? "code" : item.type === "color" ? "palette" : "content_paste",
                        clipItem: item,
                        colorHex: item.colorHex,
                        text: item.text,
                        lines: item.lines,
                        words: item.words,
                        chars: item.chars,
                        timestamp: item.timestamp
                    });
                }
            }
            results = list;
            if (selectedIndex >= results.length) {
                selectedIndex = Math.max(0, results.length - 1);
            }
            return;
        }

        // ── MODE 2: FILES ─────────────────────────────────────────────────────
        if (searchMode === 2) {
            results = [];
            selectedIndex = 0;
            return;
        }

        // ── MODE 0: ALL (APPS, MATH, ACTIONS) ──────────────────────────────────
        // 1. Math Calculation (Instant evaluation)
        if (q.length > 0) {
            const mathItem = evaluateMath(query);
            if (mathItem) {
                list.push(mathItem);
            }
        }

        // 2. System Commands
        const systemActions = [
            { name: I18n.t("action.lock"), cmd: "lock", icon: "lock", desc: I18n.t("action.lock_desc") },
            { name: I18n.t("action.shutdown"), cmd: "shutdown", icon: "power_settings_new", desc: I18n.t("action.shutdown_desc") },
            { name: I18n.t("action.restart"), cmd: "reboot", icon: "restart_alt", desc: I18n.t("action.restart_desc") },
            { name: I18n.t("action.suspend"), cmd: "suspend", icon: "bedtime", desc: I18n.t("action.suspend_desc") },
            { name: I18n.t("action.logout"), cmd: "logout", icon: "logout", desc: I18n.t("action.logout_desc") },
            { name: I18n.t("action.terminal"), cmd: "terminal", icon: "terminal", desc: I18n.t("action.terminal_desc") }
        ];

        if (q.length > 0) {
            for (let i = 0; i < systemActions.length; i++) {
                const sa = systemActions[i];
                if (sa.name.toLowerCase().includes(q) || sa.cmd.includes(q)) {
                    list.push({
                        type: "system",
                        title: sa.name,
                        subtitle: sa.desc,
                        icon: sa.icon,
                        action: sa.cmd
                    });
                }
            }
        }

        // 3. Applications from Cached List
        if (cachedApps.length === 0) {
            refreshAppsCache();
        }

        const matchedApps = [];
        for (let i = 0; i < cachedApps.length; i++) {
            const app = cachedApps[i];
            if (q.length === 0) {
                matchedApps.push({
                    type: "app",
                    title: app.name,
                    subtitle: app.subtitle,
                    category: app.category,
                    icon: app.icon,
                    entry: app.entry,
                    score: 0
                });
            } else {
                let score = -1;
                if (app.nameLower.startsWith(q)) {
                    score = 100 - app.nameLower.length;
                } else if (app.nameLower.includes(q)) {
                    score = 70 - app.nameLower.indexOf(q);
                } else if (app.genericLower.startsWith(q)) {
                    score = 50;
                } else if (app.genericLower.includes(q)) {
                    score = 40;
                } else if (app.idLower.startsWith(q) || app.idLower.includes(q)) {
                    score = 35;
                } else if (app.startupClassLower.includes(q)) {
                    score = 30;
                } else if (app.commentLower.includes(q) || app.execLower.includes(q)) {
                    score = 20;
                }

                if (score >= 0) {
                    matchedApps.push({
                        type: "app",
                        title: app.name,
                        subtitle: app.subtitle,
                        category: app.category,
                        icon: app.icon,
                        entry: app.entry,
                        score: score
                    });
                }
            }
        }

        if (q.length > 0) {
            matchedApps.sort((a, b) => b.score - a.score);
        } else {
            matchedApps.sort((a, b) => a.title.localeCompare(b.title));
        }

        // Limit results to top 12 items for fast scrolling
        const topApps = matchedApps.slice(0, 12);
        for (let i = 0; i < topApps.length; i++) {
            list.push(topApps[i]);
        }

        results = list;
        if (selectedIndex >= results.length) {
            selectedIndex = Math.max(0, results.length - 1);
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged(): void {
            root.refreshAppsCache();
            if (root.visible && root.searchMode === 0) {
                root.updateResults();
            }
        }
    }

    Connections {
        target: ClipboardService
        function onHistoryChanged(): void {
            if (root.searchMode === 1) {
                root.updateResults();
            }
        }
    }

    onQueryChanged: updateResults()

    IpcHandler {
        target: "spotlight"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }

        function clipboard(): void {
            root.openClipboard();
        }
    }
}
