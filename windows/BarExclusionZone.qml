pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData

        screen: modelData
        anchors.top: true

        implicitWidth: 1
        implicitHeight: 1
        // Reserve the bar height so windows tile below the topbar (top edge visible).
        exclusiveZone: Theme.barHeight
        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "titonium-bar-exclusion"
    }
}
