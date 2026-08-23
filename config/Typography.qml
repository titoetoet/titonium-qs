pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // ── Font Families ────────────────────────────────────────────────────────
    readonly property string fontFamily: "SF Pro Display"
    readonly property string monoFontFamily: "JetBrains Mono, SF Mono, monospace"

    // ── Font Sizes Scale ─────────────────────────────────────────────────────
    readonly property int sizeMicro: 10
    readonly property int sizeCaption: 11
    readonly property int sizeBodySm: 12
    readonly property int sizeBody: 13
    readonly property int sizeBodyLg: 14
    readonly property int sizeTitleSm: 16
    readonly property int sizeTitle: 18
    readonly property int sizeTitleLg: 22
    readonly property int sizeDisplay: 32

    // ── Font Weights ─────────────────────────────────────────────────────────
    readonly property int weightNormal: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightDemiBold: Font.DemiBold
    readonly property int weightBold: Font.Bold
}
