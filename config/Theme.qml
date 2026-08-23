pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../themes"

QtObject {
    id: root

    // Theme selector: "dark" or "light".
    property string themeName: "dark"
    readonly property var palette: themeName === "dark" ? Dark : Light

    onThemeNameChanged: {
        Quickshell.execDetached(["sh", "-c", `sed -i 's|require("themes/.*")|require("themes/'"${themeName}"'")|' ~/.config/hypr/hyprland.lua && hyprctl reload`]);
    }

    // ── Typography ───────────────────────────────────────────────────────────
    readonly property string fontFamily: Typography.fontFamily
    readonly property string monoFontFamily: Typography.monoFontFamily
    readonly property int renderType: Typography.renderType

    // ── Bar layout & Metrics proxies ─────────────────────────────────────────
    readonly property int barHeight: Metrics.barHeight
    readonly property int borderThickness: Metrics.borderThickness
    readonly property int innerRadius: Metrics.innerRadius
    readonly property int barContentMargin: Metrics.barContentMargin
    readonly property int widgetHeight: Metrics.widgetHeight
    readonly property int widgetSpacing: Metrics.widgetSpacing

    // ── Raw Palette Colours ──────────────────────────────────────────────────
    readonly property color surfaceColour: palette.surfaceColour
    readonly property color barSurfaceColour: palette.barSurfaceColour
    readonly property color surfaceContainerColour: palette.surfaceContainerColour
    readonly property color contentColour: palette.contentColour
    readonly property color onSurfaceVariantColour: palette.onSurfaceVariantColour
    readonly property color accentColour: palette.accentColour
    readonly property color popupShadowColour: palette.popupShadowColour

    // ── Semantic Color Tokens ────────────────────────────────────────────────
    readonly property color borderSubtle: Qt.alpha(contentColour, 0.08)
    readonly property color borderDefault: Qt.alpha(contentColour, 0.12)
    readonly property color surfaceHover: Qt.alpha(contentColour, 0.05)
    readonly property color surfaceHoverStrong: Qt.alpha(contentColour, 0.10)
    readonly property color surfaceActive: themeName === "light"
        ? Qt.alpha(accentColour, 0.14)
        : Qt.tint(surfaceContainerColour, Qt.alpha(accentColour, 0.22))
    readonly property color badgeBackground: Qt.alpha(accentColour, 0.16)
    readonly property color textPrimary: contentColour
    readonly property color textSecondary: onSurfaceVariantColour

    // ── Icon accent colours ──────────────────────────────────────────────────
    readonly property color inputMethodIconColour: palette.inputMethodIconColour
    readonly property color downloadIconColour: palette.downloadIconColour
    readonly property color uploadIconColour: palette.uploadIconColour
    readonly property color cpuIconColour: palette.cpuIconColour
    readonly property color gpuIconColour: palette.gpuIconColour
    readonly property color memoryIconColour: palette.memoryIconColour

    // ── Popup & Dashboard Metrics ────────────────────────────────────────────
    readonly property int popupShadowRange: Metrics.popupShadowRange
    readonly property int popupAnimationDuration: Metrics.animSlow
    readonly property int dashboardWidth: Metrics.dashboardWidth
    readonly property int dashboardHeight: Metrics.dashboardHeight
    readonly property int sessionButtonSize: Metrics.sessionButtonSize
    readonly property int sessionMenuPadding: Metrics.sessionMenuPadding
    readonly property int sessionMenuSpacing: Metrics.sessionMenuSpacing
    readonly property int animationFast: Metrics.animNormal

    // Canvas bezier approximation for quarter-circle
    readonly property real circleBezier: 0.5522847498
}
