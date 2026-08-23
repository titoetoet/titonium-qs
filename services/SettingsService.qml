pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/titonium"
    readonly property string settingsFilePath: configDir + "/settings.json"
    property string avatarIcon: "person"
    property int visualizerMode: 0 // 0: Bars, 1: Waveform, 2: Floating Dots

    Component.onCompleted: {
        loadSettings();
    }

    FileView {
        id: settingsFile
        path: root.settingsFilePath
        printErrors: false
        onTextChanged: {
            root.loadSettings();
        }
    }

    function loadSettings(): void {
        const txt = settingsFile.text();
        if (!txt || txt.trim().length === 0) return;
        try {
            const data = JSON.parse(txt);
            if (data.avatarIcon && typeof data.avatarIcon === "string") {
                root.avatarIcon = data.avatarIcon;
            }
            if (typeof data.visualizerMode === "number") {
                root.visualizerMode = Math.max(0, Math.min(2, Math.floor(data.visualizerMode)));
            }
        } catch (e) {
            console.warn("Failed to parse settings.json:", e);
        }
    }

    function setAvatarIcon(iconName: string): void {
        if (!iconName) return;
        root.avatarIcon = iconName;
        saveSettings();
    }

    function cycleVisualizerMode(): void {
        setVisualizerMode((root.visualizerMode + 1) % 3);
    }

    function setVisualizerMode(mode: int): void {
        root.visualizerMode = mode;
        saveSettings();
    }

    function saveSettings(): void {
        const payload = JSON.stringify({
            avatarIcon: root.avatarIcon,
            visualizerMode: root.visualizerMode
        }, null, 2);

        Quickshell.execDetached([
            "sh", "-c",
            `mkdir -p ~/.config/titonium && cat << 'EOF' > ~/.config/titonium/settings.json\n${payload}\nEOF`
        ]);
    }
}
