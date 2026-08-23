pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // ── Bar & Screen Frame ───────────────────────────────────────────────────
    readonly property int barHeight: 40
    readonly property int borderThickness: 5
    readonly property int innerRadius: 16
    readonly property int barContentMargin: 8
    readonly property int widgetHeight: 30
    readonly property int widgetSpacing: 4

    // ── Spotlight Dimensions ─────────────────────────────────────────────────
    readonly property int spotlightWidth: 620
    readonly property int spotlightSplitWidth: 720
    readonly property int spotlightSearchHeight: 56
    readonly property int spotlightItemHeight: 52
    readonly property int spotlightMaxListHeight: 360
    readonly property int spotlightSplitListHeight: 380
    readonly property int spotlightLeftWidth: 340
    readonly property int spotlightBadgeHeight: 28
    readonly property int spotlightFooterHeight: 32
    readonly property int spotlightTopOffset: 30

    // ── Clock Popup Dimensions ───────────────────────────────────────────────
    readonly property int clockPopupWidth: 320
    readonly property int clockPopupHeight: 380
    readonly property int clockDialSize: 164
    readonly property int clockPadding: 16

    // ── Media Popup Dimensions ───────────────────────────────────────────────
    readonly property int mediaPopupWidth: 320
    readonly property int mediaPopupHeight: 205
    readonly property int mediaIconSize: 44
    readonly property int mediaVisualizerHeight: 24
    readonly property int mediaVisualizerBars: 48
    readonly property real mediaVisualizerBarWidth: 3
    readonly property real mediaVisualizerBarSpacing: 3

    // ── Notification Dimensions ──────────────────────────────────────────────
    readonly property int ncPanelWidth: 360
    readonly property real ncPanelHeightRatio: 0.60
    readonly property int notificationPopupWidth: 340
    readonly property int popupShadowRange: 15

    // ── Dashboard Dimensions ─────────────────────────────────────────────────
    readonly property int dashboardWidth: 570
    readonly property int dashboardHeight: 540
    readonly property int sessionButtonSize: 52
    readonly property int sessionMenuPadding: 12
    readonly property int sessionMenuSpacing: 8

    // ── Spacings & Margins Design Tokens ─────────────────────────────────────
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    readonly property int marginXs: 4
    readonly property int marginSm: 8
    readonly property int marginMd: 12
    readonly property int marginLg: 16
    readonly property int marginXl: 24

    // ── Corner Radii Design Tokens ───────────────────────────────────────────
    readonly property int radiusXs: 4
    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radiusLg: 10
    readonly property int radiusXl: 14
    readonly property int radiusCard: 16
    readonly property int radiusPill: 20

    // ── Icon Sizes Design Tokens ─────────────────────────────────────────────
    readonly property int iconXs: 11
    readonly property int iconSm: 14
    readonly property int iconMd: 18
    readonly property int iconLg: 20
    readonly property int iconXl: 24
    readonly property int iconHero: 32

    // ── Animation Durations ──────────────────────────────────────────────────
    readonly property int animFast: 120
    readonly property int animNormal: 180
    readonly property int animSlow: 260
}
