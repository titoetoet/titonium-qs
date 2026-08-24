pragma Singleton

import QtQuick

QtObject {
    // macOS Light Mode Palette: Ambient Glass Gradient (Top -> Bottom)
    readonly property color surfaceColour: Qt.rgba(1.0, 1.0, 1.0, 0.94)
    readonly property color surfaceColourBottom: Qt.rgba(0.92, 0.93, 0.96, 0.96)
    readonly property color barSurfaceColour: Qt.alpha("#e5e5ea", 0.70)
    // Inner Grouped Inset Cards: Translucent Inset Tint
    readonly property color surfaceContainerColour: Qt.alpha("#000000", 0.06)
    readonly property color contentColour: "#1d1d1f"
    readonly property color onSurfaceVariantColour: "#86868b"
    readonly property color accentColour: "#007aff"
    readonly property color popupShadowColour: Qt.alpha("#000000", 0.15)
    readonly property color inputMethodIconColour: "#007aff"
    readonly property color downloadIconColour: "#34c759"
    readonly property color uploadIconColour: "#32ade6"
    readonly property color cpuIconColour: "#ff9500"
    readonly property color gpuIconColour: "#af52de"
    readonly property color memoryIconColour: "#34c759"
}
