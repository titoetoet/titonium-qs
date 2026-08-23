pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property bool visible: false
    property var selectedToplevel: null

    readonly property var toplevels: ToplevelManager.toplevels.values
        .filter(toplevel => !toplevel.minimized)

    function selectRelative(offset: int): void {
        const windows = toplevels;
        if (windows.length === 0) {
            close();
            return;
        }

        const selectedIndex = windows.indexOf(selectedToplevel);
        const activeIndex = windows.indexOf(ToplevelManager.activeToplevel);
        const currentIndex = selectedIndex >= 0 ? selectedIndex : activeIndex;
        const initialIndex = currentIndex >= 0
            ? currentIndex
            : offset > 0 ? -1 : 0;

        selectedToplevel = windows[
            (initialIndex + offset + windows.length) % windows.length
        ];
        visible = true;
    }

    function next(): void {
        selectRelative(1);
    }

    function previous(): void {
        selectRelative(-1);
    }

    function accept(): void {
        const toplevel = selectedToplevel;
        close();

        if (toplevel)
            toplevel.activate();
    }

    function close(): void {
        if (!visible && selectedToplevel === null)
            return;

        visible = false;
        selectedToplevel = null;
    }

    // Leave the Hyprland submap whenever the switcher closes (key or mouse).
    Process {
        id: submapReset

        command: ["hyprctl", "dispatch", "hl.dsp.submap('')"]
    }

    onVisibleChanged: {
        if (!visible) {
            submapReset.running = true;
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.submap('')"]);
        }
    }

    IpcHandler {
        target: "window-switcher"

        function next(): void {
            root.next();
        }

        function previous(): void {
            root.previous();
        }

        function accept(): void {
            root.accept();
        }

        function close(): void {
            root.close();
        }
    }
}
