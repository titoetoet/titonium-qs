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

        screen: modelData
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        visible: WindowSwitcherService.visible
        color: Qt.alpha("black", 0.40)

        WlrLayershell.namespace: "titonium-window-switcher"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WindowSwitcherService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            item: inputRegion
        }

        Item {
            id: inputRegion
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    const point = mapToItem(switcherCard, mouse.x, mouse.y);
                    const isInsideCard = point.x >= 0
                        && point.x <= switcherCard.width
                        && point.y >= 0
                        && point.y <= switcherCard.height;

                    if (!isInsideCard)
                        WindowSwitcherService.close();
                }
            }
        }

        // ── Floating Luxury Liquid Glass HUD Card ───────────────────────────
        Item {
            id: switcherCard

            readonly property real preferredWidth: (WindowSwitcherService.toplevels.length * 222) + 40

            anchors.centerIn: parent
            width: Math.min(parent.width - 80, Math.max(340, preferredWidth))
            height: 240

            // ── Background Glass & Soft Gaussian Drop Shadow ──
            Rectangle {
                anchors.fill: parent
                radius: Theme.innerRadius
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
                    height: 36
                    radius: Theme.innerRadius - 1
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.30 : 0.12) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Layer 2: Thanh đèn giả lập (Specular Rim Sheen)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: 1.5
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.40 : 0.25) }
                        GradientStop { position: 0.5; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.85 : 0.70) }
                        GradientStop { position: 0.8; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.40 : 0.25) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            // ── Toplevel Windows Horizontal Grid / Carousel ──
            ListView {
                id: windowList
                anchors.fill: parent
                anchors.margins: 18
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: WindowSwitcherService.toplevels

                currentIndex: WindowSwitcherService.toplevels.indexOf(WindowSwitcherService.selectedToplevel)

                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        windowList.positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: Item {
                    id: windowItem

                    required property var modelData
                    readonly property bool hasModel: windowItem.modelData !== null && windowItem.modelData !== undefined
                    readonly property bool selected: windowItem.hasModel && WindowSwitcherService.selectedToplevel === windowItem.modelData
                    readonly property string winTitle: windowItem.hasModel ? (windowItem.modelData.title || windowItem.modelData.appId || "Untitled window") : "Untitled window"
                    readonly property string winAppId: windowItem.hasModel ? (windowItem.modelData.appId || "") : ""

                    width: 210
                    height: windowList.height

                    Rectangle {
                        id: tileBg
                        anchors.fill: parent
                        radius: 14
                        scale: windowItem.selected ? 1.02 : 1.0

                        color: windowItem.selected
                            ? Qt.alpha(Theme.accentColour, 0.22)
                            : (tileMa.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : Qt.alpha(Theme.contentColour, 0.04))

                        border.width: windowItem.selected ? 1.5 : 1
                        border.color: windowItem.selected
                            ? Qt.alpha(Theme.accentColour, 0.55)
                            : Qt.alpha(Theme.contentColour, 0.08)

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Metrics.animFast } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Screencopy Live Thumbnail or App Icon Card
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 136
                                radius: 9
                                color: Qt.alpha(Theme.surfaceColour, 0.75)
                                border.width: 1
                                border.color: Qt.alpha(Theme.contentColour, 0.06)
                                clip: true

                                ScreencopyView {
                                    id: windowCapture
                                    anchors.fill: parent
                                    captureSource: (windowItem.hasModel && windowItem.modelData && typeof windowItem.modelData.title !== "undefined") ? windowItem.modelData : null
                                    live: WindowSwitcherService.visible && windowCapture.captureSource !== null
                                    constraintSize: Qt.size(parent.width, parent.height)
                                    visible: hasContent
                                }

                                Image {
                                    id: fallbackAppIcon
                                    anchors.centerIn: parent
                                    width: 48
                                    height: 48
                                    source: windowItem.winAppId.length > 0 ? Quickshell.iconPath(windowItem.winAppId, "application-x-executable") : ""
                                    sourceSize.width: 48
                                    sourceSize.height: 48
                                    fillMode: Image.PreserveAspectFit
                                    visible: !windowCapture.hasContent
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: !windowCapture.hasContent && fallbackAppIcon.status !== Image.Ready
                                    iconName: "desktop_windows"
                                    iconSize: 42
                                    iconColour: Theme.onSurfaceVariantColour
                                }
                            }

                            // App Icon & Window Title
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                spacing: 8

                                Image {
                                    id: appIconMini
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    source: windowItem.winAppId.length > 0 ? Quickshell.iconPath(windowItem.winAppId, "application-x-executable") : ""
                                    sourceSize.width: 20
                                    sourceSize.height: 20
                                    fillMode: Image.PreserveAspectFit

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: parent.status !== Image.Ready
                                        iconName: "web_asset"
                                        iconSize: 18
                                        iconColour: Theme.accentColour
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: windowItem.winTitle
                                    color: windowItem.selected
                                        ? (Theme.themeName === "light" ? Theme.accentColour : "#ffffff")
                                        : Theme.textPrimary
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeBodySm
                                    font.weight: windowItem.selected ? Typography.weightBold : Typography.weightMedium
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: tileMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (windowItem.hasModel)
                                WindowSwitcherService.selectedToplevel = windowItem.modelData;
                        }
                        onClicked: {
                            if (windowItem.hasModel) {
                                WindowSwitcherService.selectedToplevel = windowItem.modelData;
                                WindowSwitcherService.accept();
                            }
                        }
                    }
                }
            }
        }
    }
}
