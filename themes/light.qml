pragma Singleton

import QtQuick

QtObject {
    readonly property color surfaceColour: "#f5f5f7"
    readonly property color barSurfaceColour: "#f5f5f7"
    readonly property color surfaceContainerColour: "#ffffff"
    readonly property color contentColour: "#1d1d1f"
    readonly property color onSurfaceVariantColour: "#6e6e73"
    readonly property color accentColour: "#0a84ff"
    readonly property color popupShadowColour: Qt.alpha("#000000", 0.12)
    readonly property color inputMethodIconColour: "#0a84ff"
    readonly property color downloadIconColour: "#34c759"
    readonly property color uploadIconColour: "#32ade6"
    readonly property color cpuIconColour: "#ff9500"
    readonly property color gpuIconColour: "#af52de"
    readonly property color memoryIconColour: "#34c759"
}
