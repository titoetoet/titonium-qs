pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"
import "../components/primitives"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property ShellScreen modelData

        readonly property bool isThisScreenActive: SpotlightService.activeScreen === modelData || (SpotlightService.activeScreen === null && modelData === Quickshell.screens[0])

        screen: modelData
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        visible: SpotlightService.visible && window.isThisScreenActive
        color: Qt.alpha("black", 0.40)

        WlrLayershell.namespace: "titonium-spotlight"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: (SpotlightService.visible && window.isThisScreenActive) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            item: inputRegion
        }

        Item {
            id: inputRegion
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    const point = mapToItem(spotlightCard, mouse.x, mouse.y);
                    const isInside = point.x >= 0
                        && point.x <= spotlightCard.width
                        && point.y >= 0
                        && point.y <= spotlightCard.height;

                    if (!isInside)
                        SpotlightService.close();
                }
            }
        }

        // Floating macOS Spotlight Card
        Item {
            id: spotlightCard

            anchors.horizontalCenter: parent.horizontalCenter
            y: Metrics.barHeight + Metrics.borderThickness + Metrics.spotlightTopOffset
            width: SpotlightService.searchMode === 1 ? Metrics.spotlightSplitWidth : Metrics.spotlightWidth
            height: cardLayout.implicitHeight

            Behavior on width { NumberAnimation { duration: Metrics.animNormal; easing.type: Easing.OutCubic } }

            // Background Card with Soft Diffused MultiEffect Shadow
            Rectangle {
                anchors.fill: parent
                radius: Metrics.radiusCard
                antialiasing: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.surfaceColour }
                    GradientStop { position: 1.0; color: Theme.surfaceColourBottom }
                }

                border.width: 1
                border.color: Theme.popupBorder

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 32
                    shadowBlur: 0.65
                    shadowVerticalOffset: 8
                    shadowColor: Theme.popupShadowColour
                }

                // Layer 1: Top Ambient Caustic Glow (Liquid glass diffusion)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 28
                    radius: Metrics.radiusCard - 1
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.28 : 0.10) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Layer 2: Thanh đèn giả lập (Specular Rim Sheen)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    height: 1.5
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.38 : 0.22) }
                        GradientStop { position: 0.5; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.80 : 0.65) }
                        GradientStop { position: 0.8; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.38 : 0.22) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            ColumnLayout {
                id: cardLayout
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                // 1. Search Bar (Top Input)
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Metrics.spotlightSearchHeight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.marginLg
                        anchors.rightMargin: Metrics.marginLg
                        spacing: Metrics.spacingMd

                        // Mode Switcher Badge (Click or Press Tab to cycle)
                        Rectangle {
                            implicitWidth: modeRow.implicitWidth + Metrics.marginLg
                            implicitHeight: Metrics.spotlightBadgeHeight
                            radius: Metrics.spotlightBadgeHeight / 2
                            color: Theme.badgeBackground

                            RowLayout {
                                id: modeRow
                                anchors.centerIn: parent
                                spacing: Metrics.spacingXs

                                MaterialIcon {
                                    iconName: SpotlightService.searchMode === 1
                                        ? "content_paste"
                                        : SpotlightService.searchMode === 2
                                            ? "folder"
                                            : "search"
                                    iconSize: Metrics.iconMd
                                    iconColour: Theme.accentColour
                                }

                                Text {
                                    text: SpotlightService.searchMode === 1
                                        ? I18n.t("spotlight.mode_clipboard")
                                        : SpotlightService.searchMode === 2
                                            ? I18n.t("spotlight.mode_files")
                                            : I18n.t("spotlight.mode_all")
                                    color: Theme.accentColour
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeBodySm
                                    font.weight: Typography.weightDemiBold
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SpotlightService.cycleMode()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                text: SpotlightService.query
                                color: Theme.textPrimary
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeTitle
                                font.weight: Typography.weightNormal
                                selectByMouse: true
                                focus: SpotlightService.visible

                                onTextChanged: {
                                    if (SpotlightService.query !== text)
                                        SpotlightService.query = text;
                                }

                                Keys.onTabPressed: event => {
                                    event.accepted = true;
                                    SpotlightService.cycleMode();
                                }

                                Keys.onUpPressed: event => {
                                    event.accepted = true;
                                    SpotlightService.selectPrevious();
                                }

                                Keys.onDownPressed: event => {
                                    event.accepted = true;
                                    SpotlightService.selectNext();
                                }

                                Keys.onReturnPressed: event => {
                                    event.accepted = true;
                                    SpotlightService.executeSelected();
                                }

                                Keys.onEscapePressed: event => {
                                    event.accepted = true;
                                    SpotlightService.close();
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text.length === 0
                                text: SpotlightService.searchMode === 1
                                    ? I18n.t("spotlight.search_clipboard")
                                    : SpotlightService.searchMode === 2
                                        ? I18n.t("spotlight.search_files")
                                        : I18n.t("spotlight.search_all")
                                color: Theme.textSecondary
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeTitle
                                opacity: 0.50
                            }
                        }

                        // ESC key badge
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 22
                            radius: Metrics.radiusSm
                            color: Theme.surfaceContainerColour
                            border.width: 1
                            border.color: Theme.borderSubtle

                            Text {
                                anchors.centerIn: parent
                                text: I18n.t("spotlight.esc_badge")
                                color: Theme.textSecondary
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                                font.weight: Typography.weightMedium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SpotlightService.close()
                            }
                        }
                    }
                }

                // Divider line
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderSubtle
                }

                // 2. Content Area: Standard 1-Column vs Raycast Split-View
                // ── 2A: CLIPBOARD RAYCAST SPLIT-VIEW (MODE 1) ─────────────────
                RowLayout {
                    id: splitViewContainer
                    visible: SpotlightService.searchMode === 1 && SpotlightService.results.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Metrics.spotlightSplitListHeight, Math.max(220, SpotlightService.results.length * Metrics.spotlightItemHeight))
                    spacing: 0

                    // Left Column: List of items (Width 340)
                    ListView {
                        id: clipListView
                        Layout.preferredWidth: Metrics.spotlightLeftWidth
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        model: SpotlightService.results
                        currentIndex: SpotlightService.selectedIndex

                        onCurrentIndexChanged: {
                            clipListView.positionViewAtIndex(currentIndex, ListView.Contain);
                        }

                        delegate: Item {
                            id: clipItemDelegate

                            required property var modelData
                            required property int index

                            readonly property var itemData: clipItemDelegate.modelData
                            readonly property bool hasData: itemData !== null && itemData !== undefined
                            readonly property string itemColorHex: (hasData && itemData.colorHex) ? String(itemData.colorHex) : ""
                            readonly property string itemIcon: (hasData && itemData.icon) ? String(itemData.icon) : "content_paste"
                            readonly property string itemTitle: (hasData && itemData.title) ? String(itemData.title) : ""
                            readonly property string itemSubtitle: (hasData && itemData.subtitle) ? String(itemData.subtitle) : ""

                            readonly property bool isSelected: SpotlightService.selectedIndex === clipItemDelegate.index

                            width: clipListView.width
                            height: Metrics.spotlightItemHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.marginSm
                                anchors.rightMargin: Metrics.marginSm
                                anchors.topMargin: 2
                                anchors.bottomMargin: 2
                                radius: Metrics.radiusLg
                                border.width: clipItemDelegate.isSelected ? 1 : 0
                                border.color: clipItemDelegate.isSelected ? Qt.alpha(Theme.accentColour, 0.40) : "transparent"

                                color: clipItemDelegate.isSelected
                                    ? Qt.alpha(Theme.accentColour, 0.22)
                                    : clipMouse.containsMouse
                                        ? Qt.alpha(Theme.contentColour, 0.08)
                                        : "transparent"

                                Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Metrics.marginSm + 2
                                    anchors.rightMargin: Metrics.marginSm + 2
                                    spacing: Metrics.spacingSm + 2

                                    // Type Icon or Color Box
                                    Item {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Metrics.radiusSm
                                            visible: clipItemDelegate.itemColorHex.length > 0
                                            color: clipItemDelegate.itemColorHex.length > 0 ? clipItemDelegate.itemColorHex : "transparent"
                                            border.width: 1
                                            border.color: Theme.borderDefault
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Metrics.radiusSm
                                            visible: clipItemDelegate.itemColorHex.length === 0
                                            color: clipItemDelegate.isSelected ? Theme.accentColour : Theme.badgeBackground

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                iconName: clipItemDelegate.itemIcon
                                                iconSize: Metrics.iconMd
                                                iconColour: clipItemDelegate.isSelected ? "#ffffff" : Theme.accentColour
                                            }
                                        }
                                    }

                                    // Title & Time
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: clipItemDelegate.itemTitle
                                            color: clipItemDelegate.isSelected ? (Theme.themeName === "light" ? Theme.accentColour : "#ffffff") : Theme.textPrimary
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.sizeBodySm
                                            font.weight: clipItemDelegate.isSelected ? Typography.weightBold : Typography.weightMedium
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: clipItemDelegate.itemSubtitle
                                            color: clipItemDelegate.isSelected ? Qt.alpha(Theme.contentColour, 0.75) : Theme.textSecondary
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.sizeMicro
                                            font.weight: Typography.weightNormal
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: clipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SpotlightService.selectedIndex = clipItemDelegate.index;
                                    if (clipItemDelegate.hasData)
                                        SpotlightService.executeItem(clipItemDelegate.itemData);
                                }
                            }
                        }
                    }

                    // Vertical Split Divider
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Theme.borderSubtle
                    }

                    // Right Column: Live Preview Pane
                    Item {
                        id: previewPane
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property var activeItem: (SpotlightService.results.length > 0 && SpotlightService.selectedIndex >= 0 && SpotlightService.selectedIndex < SpotlightService.results.length)
                            ? SpotlightService.results[SpotlightService.selectedIndex]
                            : null

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Metrics.marginMd + 2
                            spacing: Metrics.spacingSm

                            // Header Info Badge
                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    implicitWidth: typeBadgeText.implicitWidth + Metrics.marginMd
                                    implicitHeight: 22
                                    radius: Metrics.radiusSm
                                    color: Theme.badgeBackground

                                    Text {
                                        id: typeBadgeText
                                        anchors.centerIn: parent
                                        text: previewPane.activeItem ? (previewPane.activeItem.clipItem?.type?.toUpperCase() || I18n.t("clipboard.type_text")) : I18n.t("clipboard.empty")
                                        color: Theme.accentColour
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.sizeMicro
                                        font.weight: Typography.weightBold
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: previewPane.activeItem ? (previewPane.activeItem.subtitle || "") : ""
                                    color: Theme.textSecondary
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                }
                            }

                            // Color Swatch Preview if applicable
                            Rectangle {
                                visible: previewPane.activeItem !== null && previewPane.activeItem.colorHex !== undefined && previewPane.activeItem.colorHex.length > 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: Metrics.radiusMd
                                color: previewPane.activeItem?.colorHex || "transparent"
                                border.width: 1
                                border.color: Theme.borderDefault

                                Text {
                                    anchors.centerIn: parent
                                    text: previewPane.activeItem?.colorHex || ""
                                    color: "white"
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeBodySm
                                    font.weight: Typography.weightBold
                                }
                            }

                            // Scrollable Text Preview
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Metrics.radiusMd
                                color: Theme.themeName === "light" ? Qt.alpha("#000000", 0.04) : Qt.alpha("#ffffff", 0.04)
                                clip: true

                                Flickable {
                                    id: previewFlickable
                                    anchors.fill: parent
                                    anchors.margins: Metrics.marginSm + 2
                                    contentWidth: width
                                    contentHeight: previewContentText.implicitHeight
                                    boundsBehavior: Flickable.StopAtBounds

                                    Text {
                                        id: previewContentText
                                        width: previewFlickable.width
                                        text: {
                                            if (!previewPane.activeItem || !previewPane.activeItem.text) return I18n.t("clipboard.empty");
                                            const raw = previewPane.activeItem.text;
                                            if (raw.length > 6000) {
                                                return raw.substring(0, 6000) + "\n\n... [" + (raw.length - 6000) + " more characters - press Enter to copy full content]";
                                            }
                                            return raw;
                                        }
                                        color: Theme.textPrimary
                                        font.family: Typography.monoFontFamily
                                        font.pixelSize: Typography.sizeCaption
                                        wrapMode: Text.WrapAnywhere
                                        lineHeight: 1.3
                                    }
                                }
                            }

                            // Meta Stats
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Metrics.spacingSm + 2

                                Text {
                                    text: I18n.t("clipboard.chars", { n: previewPane.activeItem?.chars || 0 })
                                    color: Theme.textSecondary
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                }

                                Text {
                                    text: I18n.t("clipboard.words", { n: previewPane.activeItem?.words || 0 })
                                    color: Theme.textSecondary
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                }

                                Text {
                                    text: I18n.t("clipboard.lines", { n: previewPane.activeItem?.lines || 1 })
                                    color: Theme.textSecondary
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: I18n.t("spotlight.hint_paste")
                                    color: Theme.accentColour
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                    font.weight: Typography.weightBold
                                }
                            }
                        }
                    }
                }

                // ── 2B: STANDARD 1-COLUMN RESULTS LIST (MODE 0 & MODE 2) ──────
                ListView {
                    id: resultsList
                    visible: SpotlightService.searchMode !== 1 && SpotlightService.results.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Metrics.spotlightMaxListHeight, count * Metrics.spotlightItemHeight)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: SpotlightService.results
                    currentIndex: SpotlightService.selectedIndex

                    onCurrentIndexChanged: {
                        resultsList.positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    delegate: Item {
                        id: resultItem

                        required property var modelData
                        required property int index

                        readonly property var itemData: resultItem.modelData
                        readonly property bool hasData: itemData !== null && itemData !== undefined
                        readonly property string itemType: (hasData && itemData.type) ? String(itemData.type) : ""
                        readonly property string itemIcon: (hasData && itemData.icon) ? String(itemData.icon) : "play_arrow"
                        readonly property string itemTitle: (hasData && itemData.title) ? String(itemData.title) : ""
                        readonly property string itemSubtitle: (hasData && itemData.subtitle) ? String(itemData.subtitle) : ""
                        readonly property string itemCategory: (hasData && itemData.category) ? String(itemData.category) : ""

                        readonly property bool isSelected: SpotlightService.selectedIndex === resultItem.index

                        width: resultsList.width
                        height: Metrics.spotlightItemHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.marginSm
                            anchors.rightMargin: Metrics.marginSm
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            radius: Metrics.radiusLg
                            border.width: resultItem.isSelected ? 1 : 0
                            border.color: resultItem.isSelected ? Qt.alpha(Theme.accentColour, 0.40) : "transparent"

                            color: resultItem.isSelected
                                ? Qt.alpha(Theme.accentColour, 0.22)
                                : itemMouse.containsMouse
                                    ? Qt.alpha(Theme.contentColour, 0.08)
                                    : "transparent"

                            Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.marginSm + 2
                                anchors.rightMargin: Metrics.marginSm + 2
                                spacing: Metrics.spacingMd

                                // Icon (App Icon or Action Icon)
                                Item {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignVCenter

                                    Image {
                                        id: appIconImage
                                        anchors.fill: parent
                                        visible: resultItem.itemType === "app"
                                        source: resultItem.itemType === "app"
                                            ? Quickshell.iconPath(resultItem.itemIcon, "application-x-executable")
                                            : ""
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: resultItem.itemType !== "app"
                                        radius: Metrics.radiusMd
                                        color: resultItem.isSelected ? Theme.accentColour : Theme.badgeBackground

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            iconName: resultItem.itemIcon
                                            iconSize: Metrics.iconLg
                                            iconColour: resultItem.isSelected ? "#ffffff" : Theme.accentColour
                                        }
                                    }
                                }

                                // Title & Subtitle
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultItem.itemTitle
                                        color: resultItem.isSelected ? (Theme.themeName === "light" ? Theme.accentColour : "#ffffff") : Theme.textPrimary
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.sizeBody
                                        font.weight: resultItem.isSelected ? Typography.weightBold : Typography.weightDemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultItem.itemSubtitle
                                        color: resultItem.isSelected ? Qt.alpha(Theme.contentColour, 0.75) : Theme.textSecondary
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.sizeCaption
                                        font.weight: Typography.weightNormal
                                        elide: Text.ElideRight
                                    }
                                }

                                // Category or Action Chip
                                Rectangle {
                                    visible: resultItem.itemCategory.length > 0
                                    implicitWidth: catText.implicitWidth + Metrics.marginMd
                                    implicitHeight: 20
                                    radius: Metrics.radiusLg
                                    color: Theme.surfaceContainerColour

                                    Text {
                                        id: catText
                                        anchors.centerIn: parent
                                        text: resultItem.itemCategory
                                        color: Theme.textSecondary
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.sizeMicro
                                        font.weight: Typography.weightMedium
                                    }
                                }

                                // Return Enter Indicator
                                Rectangle {
                                    visible: resultItem.isSelected
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: Metrics.radiusSm
                                    color: Theme.accentColour

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        iconName: "keyboard_return"
                                        iconSize: Metrics.iconSm
                                        iconColour: Theme.themeName === "light" ? "#ffffff" : Theme.surfaceColour
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SpotlightService.selectedIndex = resultItem.index;
                                if (resultItem.hasData)
                                    SpotlightService.executeItem(resultItem.itemData);
                            }
                        }
                    }
                }

                // ── 2C: EMPTY STATE CARD (WHEN NO MATCHES FOUND) ──────────────
                Item {
                    id: emptyStateCard
                    visible: SpotlightService.results.length === 0 && SpotlightService.query.trim().length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Metrics.spacingSm

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: Qt.alpha(Theme.contentColour, 0.06)

                            MaterialIcon {
                                anchors.centerIn: parent
                                iconName: "search_off"
                                iconSize: Metrics.iconXl
                                iconColour: Theme.textSecondary
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("spotlight.no_results_title")
                            color: Theme.textPrimary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBody
                            font.weight: Typography.weightDemiBold
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("spotlight.no_results_desc", { q: SpotlightService.query })
                            color: Theme.textSecondary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            font.weight: Typography.weightNormal
                        }
                    }
                }

                // Divider line before footer
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderSubtle
                }

                // 3. Footer Bar
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Metrics.spotlightFooterHeight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.marginLg
                        anchors.rightMargin: Metrics.marginLg

                        Text {
                            text: SpotlightService.searchMode === 1
                                ? I18n.t("spotlight.footer_clipboard")
                                : SpotlightService.searchMode === 2
                                    ? I18n.t("spotlight.footer_files")
                                    : I18n.t("spotlight.footer_spotlight")
                            color: Theme.accentColour
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeMicro
                            font.weight: Typography.weightBold
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 8

                            KbdBadge {
                                keyText: "Tab"
                                labelText: I18n.t("spotlight.hint_navigate")
                            }

                            KbdBadge {
                                keyText: "↵"
                                labelText: SpotlightService.searchMode === 1 ? I18n.t("spotlight.hint_paste") : I18n.t("spotlight.hint_open")
                            }

                            KbdBadge {
                                keyText: "Esc"
                                labelText: I18n.t("spotlight.hint_close")
                            }
                        }
                    }
                }

                component KbdBadge: RowLayout {
                    id: kbdRoot
                    required property string keyText
                    required property string labelText

                    spacing: 5

                    Rectangle {
                        implicitHeight: 18
                        implicitWidth: Math.max(18, keyLabel.implicitWidth + 8)
                        radius: 4
                        color: Theme.surfaceContainerColour
                        border.width: 1
                        border.color: Theme.borderDefault

                        Text {
                            id: keyLabel
                            anchors.centerIn: parent
                            text: kbdRoot.keyText
                            color: Theme.textPrimary
                            font.family: Typography.fontFamily
                            font.pixelSize: 10
                            font.weight: Typography.weightBold
                        }
                    }

                    Text {
                        text: kbdRoot.labelText
                        color: Theme.textSecondary
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightMedium
                    }
                }
            }
        }

        Connections {
            target: SpotlightService
            function onVisibleChanged(): void {
                if (SpotlightService.visible) {
                    Qt.callLater(function() {
                        searchInput.forceActiveFocus();
                    });
                }
            }
        }
    }
}
