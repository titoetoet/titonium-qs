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
        color: Qt.alpha("black", 0.42)

        WlrLayershell.namespace: "titonium-window-switcher"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

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

        Rectangle {
            id: switcherCard

            readonly property real preferredWidth: WindowSwitcherService.toplevels.length * 250 + 40

            anchors.centerIn: parent
            width: Math.min(parent.width - 80, Math.max(320, preferredWidth))
            height: 230
            // ── Isolated Background & Shadow ──
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
                    blurMax: 36
                    shadowBlur: 0.95
                    shadowVerticalOffset: 12
                    shadowColor: Theme.popupShadowColour
                }

                // Layer 1: Top Ambient Diffuse Glow
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 24
                    radius: Theme.innerRadius - 1
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.25 : 0.06) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Layer 2: Horizontal Specular Rim Sheen
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.30 : 0.14) }
                        GradientStop { position: 0.5; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.65 : 0.38) }
                        GradientStop { position: 0.8; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.30 : 0.14) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                GridView {
                    id: windowGrid

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    flow: GridView.TopToBottom
                    cellWidth: 250
                    cellHeight: 190
                    flickableDirection: Flickable.HorizontalFlick
                    model: WindowSwitcherService.toplevels

                    delegate: Item {
                        id: windowItem

                        required property var modelData
                        readonly property bool hasModel: windowItem.modelData !== null && windowItem.modelData !== undefined
                        readonly property bool selected: windowItem.hasModel && WindowSwitcherService.selectedToplevel === windowItem.modelData
                        readonly property string winTitle: windowItem.hasModel ? (windowItem.modelData.title || windowItem.modelData.appId || "Untitled window") : "Untitled window"

                        width: windowGrid.cellWidth
                        height: windowGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 14
                            color: windowItem.selected
                                ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.accentColour, 0.18))
                                : Theme.surfaceContainerColour
                            border.width: windowItem.selected ? 2 : 0
                            border.color: Theme.accentColour

                            Behavior on border.width {
                                NumberAnimation { duration: Theme.animationFast }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Rectangle {
                                    width: parent.width
                                    height: 124
                                    radius: 8
                                    color: Qt.alpha(Theme.surfaceColour, 0.65)
                                    clip: true

                                    ScreencopyView {
                                        id: windowCapture

                                        anchors.fill: parent
                                        captureSource: (windowItem.hasModel && windowItem.modelData && typeof windowItem.modelData.title !== "undefined") ? windowItem.modelData : null
                                        live: WindowSwitcherService.visible && windowCapture.captureSource !== null
                                        constraintSize: Qt.size(parent.width, parent.height)
                                        visible: hasContent
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: !windowCapture.hasContent
                                        iconName: "desktop_windows"
                                        iconSize: 36
                                        iconColour: Theme.onSurfaceVariantColour
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: 7

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        iconName: "web_asset"
                                        iconSize: 16
                                        iconColour: Theme.accentColour
                                    }

                                    Text {
                                        width: parent.width - 23
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: windowItem.winTitle
                                        color: Theme.contentColour
                                        font.pixelSize: 11
                                        font.weight: windowItem.selected ? Font.DemiBold : Font.Normal
                                    }
                                }
                            }
                        }

                        MouseArea {
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
}
