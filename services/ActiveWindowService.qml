pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property string title: "Desktop"
    property string appClass: ""
    property string iconName: ""
    property var classIconMap: ({})
    property bool iconMapBuilt: false
    property string address: ""
    property string workspaceName: ""
    property string monitorName: ""
    property int pid: 0
    property bool floating: false
    property bool fullscreen: false
    property bool valid: false

    function refresh(): void {
        if (!activeWindowQuery.running)
            activeWindowQuery.running = true;
    }

    function updateWindow(data: var): void {
        if (!data || Object.keys(data).length === 0) {
            title = "Desktop";
            appClass = "";
            iconName = "";
            address = "";
            workspaceName = "";
            monitorName = "";
            pid = 0;
            floating = false;
            fullscreen = false;
            valid = false;
            return;
        }

        title = data.title || "Untitled window";
        appClass = data.initialClass || data.class || "";
        iconName = resolveIconName(appClass);
        address = data.address || "";
        workspaceName = data.workspace?.name || "";
        monitorName = data.monitor || "";
        pid = Number(data.pid) || 0;
        floating = data.floating ?? false;
        fullscreen = data.fullscreen === true || data.fullscreen === 1;
        valid = true;
    }
    function buildIconMap(): void {
        const map = {};
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++) {
            const sc = apps[i].startupClass;
            if (sc && sc.length > 0)
                map[sc.toLowerCase()] = apps[i].icon;
        }
        classIconMap = map;
        iconMapBuilt = true;
    }

    function resolveIconName(appClass: string): string {
        if (!appClass)
            return "";
        const cls = appClass.toLowerCase();
        if (!iconMapBuilt)
            buildIconMap();
        if (classIconMap[cls])
            return classIconMap[cls];
        const entry = DesktopEntries.heuristicLookup(appClass);
        if (entry && entry.icon)
            return entry.icon;
        if (Quickshell.hasThemeIcon(cls))
            return cls;
        const base = cls.split(".").pop();
        if (base && base !== cls && Quickshell.hasThemeIcon(base))
            return base;
        return "";
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "activewindow" || event.name === "closewindow")
                debounceTimer.restart();
        }
    }

    // Hyprland fires activewindow on every focus change. Debounce so we do not
    // spawn hyprctl once per event during rapid focus switches.
    Timer {
        id: debounceTimer

        interval: 120
        onTriggered: root.refresh()
    }

    Process {
        id: activeWindowQuery

        command: ["hyprctl", "-j", "activewindow"]

        stdout: StdioCollector {
            id: activeWindowOutput
        }

        onExited: {
            try {
                root.updateWindow(JSON.parse(activeWindowOutput.text));
            } catch (error) {
                root.updateWindow({});
            }
        }
    }
}
