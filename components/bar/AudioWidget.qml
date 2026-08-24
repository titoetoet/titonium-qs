pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Pipewire
import "../../config"
import "../../services"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: dropdown.inputRegion
    implicitWidth: dropdown.implicitWidth
    implicitHeight: dropdown.implicitHeight

    BarDropdown {
        id: dropdown

        expanded: root.expanded
        collapsedWidth: Theme.widgetHeight
        surfaceWidth: 340
        surfaceHeight: content.implicitHeight + 24

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12

            // ── 1. Master Volume Control Section (Clean Single Surface) ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Header row: Naked Icon + Title + Value + Mute Icon
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialIcon {
                        iconName: AudioService.muted ? "volume_off"
                            : AudioService.volume < 0.34 ? "volume_down" : "volume_up"
                        iconSize: 19
                        iconColour: AudioService.muted ? Theme.onSurfaceVariantColour : Theme.contentColour
                    }

                    Text {
                        text: "Sound"
                        color: Theme.contentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeTitleSm
                        font.weight: Typography.weightBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: AudioService.muted ? "Muted" : Math.round(AudioService.volume * 100) + "%"
                        color: Qt.alpha(Theme.contentColour, 0.65)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightMedium
                    }

                    // Minimal Mute Action Icon
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: mutePointer.containsMouse ? Qt.alpha(Theme.contentColour, 0.14) : "transparent"

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        MaterialIcon {
                            anchors.centerIn: parent
                            iconName: AudioService.muted ? "volume_off" : "volume_up"
                            iconSize: 15
                            iconColour: AudioService.muted ? Theme.accentColour : Theme.onSurfaceVariantColour
                        }

                        MouseArea {
                            id: mutePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMuted()
                        }
                    }
                }

                // Volume Slider Bar (visionOS Liquid Glass Inset Trench)
                Rectangle {
                    id: volumeSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    color: "transparent"

                    readonly property real trackX: 2
                    readonly property real trackWidth: width - 4

                    // Liquid Inset Recessed Groove
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: volumeSlider.trackX
                        width: volumeSlider.trackWidth
                        height: 7
                        radius: 3.5
                        color: Qt.rgba(0.0, 0.0, 0.0, 0.35)
                        border.width: 1
                        border.color: Qt.alpha("#ffffff", 0.06)
                    }

                    // Fluid Neon Fill
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: volumeSlider.trackX
                        width: volumeSlider.trackWidth * AudioService.volume
                        height: 7
                        radius: 3.5
                        color: AudioService.muted ? Theme.onSurfaceVariantColour : Theme.accentColour

                        gradient: AudioService.muted ? null : activeGrad

                        Gradient {
                            id: activeGrad
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#6272a4" } // Dracula Comment Blue
                            GradientStop { position: 1.0; color: "#8be9fd" } // Dracula Cyan
                        }
                    }

                    // Floating Glass Bead Thumb
                    Rectangle {
                        id: thumb
                        anchors.verticalCenter: parent.verticalCenter
                        x: volumeSlider.trackX + volumeSlider.trackWidth * AudioService.volume - width / 2
                        width: sliderMouse.pressed ? 18 : (sliderMouse.containsMouse ? 16 : 14)
                        height: width
                        radius: width / 2
                        color: "#ffffff"
                        border.width: 1
                        border.color: Qt.alpha("#000000", 0.12)

                        Behavior on width { NumberAnimation { duration: Metrics.animFast; easing.type: Easing.OutQuad } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowBlur: 0.6
                            shadowVerticalOffset: 2
                            shadowColor: Qt.alpha("#000000", 0.35)
                        }
                    }

                    MouseArea {
                        id: sliderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function setFromX(x: real): void {
                            const t = (x - volumeSlider.trackX) / volumeSlider.trackWidth;
                            AudioService.setVolume(Math.max(0, Math.min(1, t)));
                        }
                        onPressed: setFromX(mouseX)
                        onPositionChanged: if (pressed) setFromX(mouseX)
                    }
                }
            }

            function getSinkIcon(node: var): string {
                if (!node) return "speaker";
                const desc = ((node.description || node.name || "") + "").toLowerCase();
                if (desc.includes("headphone") || desc.includes("headset") || desc.includes("earphone") || desc.includes("airpods") || desc.includes("buds"))
                    return "headphones";
                if (desc.includes("blue") || desc.includes("bt"))
                    return "bluetooth";
                if (desc.includes("hdmi") || desc.includes("displayport") || desc.includes("tv"))
                    return "tv";
                return "speaker";
            }

            function getSourceIcon(node: var): string {
                if (!node) return "mic";
                const desc = ((node.description || node.name || "") + "").toLowerCase();
                if (desc.includes("headset") || desc.includes("headphone"))
                    return "headset_mic";
                if (desc.includes("blue") || desc.includes("bt"))
                    return "bluetooth";
                return "mic";
            }

            // Soft Refractive Divider Line 1
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                visible: (AudioService.sinks && AudioService.sinks.length > 0)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // ── 2. Output Devices List (Fluid Pills) ───
            ColumnLayout {
                Layout.fillWidth: true
                visible: (AudioService.sinks && AudioService.sinks.length > 0)
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.bottomMargin: 2
                    text: "Output"
                    color: Qt.alpha(Theme.contentColour, 0.55)
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeCaption
                    font.weight: Typography.weightDemiBold
                }

                Repeater {
                    model: (AudioService.sinks && AudioService.sinks.length > 0) ? AudioService.sinks : []

                    delegate: Rectangle {
                        id: sinkBtn
                        required property var modelData
                        readonly property bool hasNode: sinkBtn.modelData !== null && sinkBtn.modelData !== undefined
                        readonly property bool isCurrent: sinkBtn.hasNode && AudioService.currentSinkId === sinkBtn.modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 10
                        color: isCurrent
                            ? Qt.alpha(Theme.contentColour, 0.14)
                            : (pointer.containsMouse ? Qt.alpha(Theme.contentColour, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            MaterialIcon {
                                iconName: content.getSinkIcon(sinkBtn.modelData)
                                iconSize: 18
                                iconColour: sinkBtn.isCurrent ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.55)
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: sinkBtn.hasNode ? (sinkBtn.modelData.description || sinkBtn.modelData.name || "Default Output") : "Default Output"
                                color: Theme.contentColour
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: sinkBtn.isCurrent ? Typography.weightMedium : Typography.weightNormal
                            }

                            MaterialIcon {
                                visible: sinkBtn.isCurrent
                                iconName: "check"
                                iconSize: 16
                                iconColour: Theme.contentColour
                            }
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (sinkBtn.hasNode)
                                    AudioService.setSink(sinkBtn.modelData.id);
                            }
                        }
                    }
                }
            }

            // Soft Refractive Divider Line 2
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                visible: (AudioService.sources && AudioService.sources.length > 0)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // ── 3. Input Devices List (Fluid Pills) ───
            ColumnLayout {
                Layout.fillWidth: true
                visible: (AudioService.sources && AudioService.sources.length > 0)
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.bottomMargin: 2
                    text: "Input"
                    color: Qt.alpha(Theme.contentColour, 0.55)
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeCaption
                    font.weight: Typography.weightDemiBold
                }

                Repeater {
                    model: (AudioService.sources && AudioService.sources.length > 0) ? AudioService.sources : []

                    delegate: Rectangle {
                        id: srcBtn
                        required property var modelData
                        readonly property bool hasNode: srcBtn.modelData !== null && srcBtn.modelData !== undefined
                        readonly property bool isCurrent: srcBtn.hasNode && AudioService.currentSourceId === srcBtn.modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 10
                        color: isCurrent
                            ? Qt.alpha(Theme.contentColour, 0.14)
                            : (pointer.containsMouse ? Qt.alpha(Theme.contentColour, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            MaterialIcon {
                                iconName: content.getSourceIcon(srcBtn.modelData)
                                iconSize: 18
                                iconColour: srcBtn.isCurrent ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.55)
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: srcBtn.hasNode ? (srcBtn.modelData.description || srcBtn.modelData.name || "Default Input") : "Default Input"
                                color: Theme.contentColour
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: srcBtn.isCurrent ? Typography.weightMedium : Typography.weightNormal
                            }

                            MaterialIcon {
                                visible: srcBtn.isCurrent
                                iconName: "check"
                                iconSize: 16
                                iconColour: Theme.contentColour
                            }
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (srcBtn.hasNode)
                                    AudioService.setSource(srcBtn.modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        iconName: (!AudioService.sink || AudioService.muted) ? "volume_off"
            : AudioService.volume < 0.34 ? "volume_down" : "volume_up"
        accessibleName: "Audio"
        active: root.expanded
        onTriggered: root.expanded = !root.expanded
    }
}

