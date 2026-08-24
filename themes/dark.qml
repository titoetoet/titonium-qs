pragma Singleton

import QtQuick

QtObject {
    // Outer Popup Backdrop: Dracula PRO Morbius Obsidian Surface (#181820 -> #14141a)
    readonly property color surfaceColour: Qt.rgba(0.094, 0.094, 0.125, 0.96)
    readonly property color surfaceColourBottom: Qt.rgba(0.078, 0.078, 0.102, 0.98)
    readonly property color barSurfaceColour: Qt.rgba(0.094, 0.094, 0.125, 0.88)

    // Inner Inset Surfaces & Hover Pills: Morbius Selection (#2b2b3b)
    readonly property color surfaceContainerColour: Qt.rgba(0.169, 0.169, 0.231, 0.50)

    // Typography & Accents (Dracula Foreground #f8f8f2 & Comment Blue #6272a4 Accent)
    readonly property color contentColour: "#f8f8f2"
    readonly property color onSurfaceVariantColour: "#6272a4"
    readonly property color accentColour: "#6272a4"
    readonly property color popupShadowColour: Qt.rgba(0.0, 0.0, 0.0, 0.38)

    // Functional & Hardware Icons (Dracula Signature Spectrum)
    readonly property color inputMethodIconColour: "#ff5555" // Dracula Red
    readonly property color downloadIconColour: "#50fa7b"    // Dracula Green
    readonly property color uploadIconColour: "#8be9fd"      // Dracula Cyan
    readonly property color cpuIconColour: "#ffb86c"         // Dracula Orange
    readonly property color gpuIconColour: "#ff79c6"         // Dracula Pink
    readonly property color memoryIconColour: "#50fa7b"      // Dracula Green
}






