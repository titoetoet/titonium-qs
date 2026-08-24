pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // ── Font Families ────────────────────────────────────────────────────────
    readonly property string fontFamily: "SF Pro Display"
    readonly property string monoFontFamily: "JetBrains Mono, SF Mono, monospace"

    // ── Unified Font Sizes Scale (macOS / GNOME HIG Harmonized) ─────────────
    readonly property int sizeMicro: 11    // Badges, tags, counters, indicators
    readonly property int sizeCaption: 12  // Secondary subtexts, timestamps, metadata
    readonly property int sizeBodySm: 12   // Compact body, small table values
    readonly property int sizeBody: 13     // Main body, app titles, inputs, list items
    readonly property int sizeBodyLg: 14   // Section subheaders, prominent items
    readonly property int sizeTitleSm: 15  // Card/Widget headers, modal titles
    readonly property int sizeTitle: 16    // Primary view titles
    readonly property int sizeTitleLg: 20  // Prominent headers, dialog titles
    readonly property int sizeDisplay: 32  // Large clocks, hero numbers

    // ── Font Weights ─────────────────────────────────────────────────────────
    readonly property int weightNormal: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightDemiBold: Font.DemiBold
    readonly property int weightBold: Font.Bold

    // ── Rendering ────────────────────────────────────────────────────────────
    readonly property int renderType: Text.NativeRendering
}
