pragma Singleton

import QtQuick

QtObject {
    readonly property color surfaceColour: "#f2191114"
    readonly property color barSurfaceColour: "#b3191114"
    readonly property color surfaceContainerColour: Qt.alpha(contentColour, 0.10)
    readonly property color contentColour: "#efdfe2"
    readonly property color onSurfaceVariantColour: "#d5c2c6"
    readonly property color accentColour: "#ffb4ab"
    readonly property color popupShadowColour: Qt.alpha("#000000", 0.65)
    readonly property color inputMethodIconColour: "#ffb0ca"
    readonly property color downloadIconColour: "#8bd5ca"
    readonly property color uploadIconColour: "#91d7e3"
    readonly property color cpuIconColour: "#eed49f"
    readonly property color gpuIconColour: "#c6a0f6"
    readonly property color memoryIconColour: "#a6e3a1"
}
