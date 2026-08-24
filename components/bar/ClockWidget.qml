pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: inputArea

    readonly property int popupWidth: Metrics.clockPopupWidth
    readonly property int popupHeight: Math.min(Metrics.clockPopupHeight, Math.max(300, Math.floor((Quickshell.screens[0]?.height || 1080) * 0.45)))
    readonly property int joinDepth: Metrics.innerRadius
    readonly property int panelTop: Metrics.barHeight
        - (Metrics.barHeight - Metrics.widgetHeight) / 2
        + Metrics.borderThickness

    implicitWidth: trigger.implicitWidth
    implicitHeight: Metrics.widgetHeight

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property var now: clock.date
    readonly property int hours: now.getHours()
    readonly property int minutes: now.getMinutes()
    readonly property int seconds: now.getSeconds()

    readonly property real hourAngle: ((hours % 12) + minutes / 60.0 + seconds / 3600.0) * 30.0
    readonly property real minuteAngle: (minutes + seconds / 60.0) * 6.0
    readonly property real secondAngle: seconds * 6.0

    readonly property string timezoneName: {
        try {
            return Intl.DateTimeFormat().resolvedOptions().timeZone || "Asia/Ho_Chi_Minh";
        } catch (e) {
            return "Asia/Ho_Chi_Minh";
        }
    }

    readonly property string timezoneOffset: {
        const off = -now.getTimezoneOffset() / 60;
        const sign = off >= 0 ? "+" : "-";
        const absOff = Math.abs(off);
        const h = Math.floor(absOff);
        const m = Math.floor((absOff - h) * 60);
        return "UTC" + sign + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
    }

    Item {
        id: inputArea

        anchors.top: parent.top
        anchors.right: parent.right
        width: root.expanded ? root.popupWidth : trigger.implicitWidth
        height: root.expanded ? root.panelTop + panel.height : Theme.widgetHeight
    }

    PopupPanel {
        id: panel

        open: root.expanded
        closedTransformOrigin: Item.TopRight
        anchors.right: parent.right
        y: root.panelTop
        width: root.popupWidth
        height: root.joinDepth + root.popupHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // ── Luxury Swiss Horology Watch Face (Borderless, Large & Elegant) ──
            Item {
                id: clockFaceContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 204
                Layout.preferredHeight: 204

                // Outer Polished Metallic Bezel
                Rectangle {
                    id: outerBezel
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: Qt.alpha(Theme.contentColour, 0.18)

                    // Inner Sunray Obsidian Dial
                    Rectangle {
                        id: dialSurface
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: width / 2
                        antialiasing: true

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.alpha(Theme.surfaceColour, 0.85) }
                            GradientStop { position: 0.6; color: Qt.alpha(Theme.surfaceColourBottom, 0.95) }
                            GradientStop { position: 1.0; color: Qt.alpha("#000000", 0.40) }
                        }

                        border.width: 1
                        border.color: Qt.alpha(Theme.contentColour, 0.10)

                        // Outer Concentric Track (Chapter Ring)
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: parent.height - 16
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.alpha(Theme.contentColour, 0.08)
                        }

                        // Inner Subtle Ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 64
                            height: parent.height - 64
                            radius: width / 2
                            color: "transparent"
                            border.width: 0.8
                            border.color: Qt.alpha(Theme.contentColour, 0.05)
                        }

                        // 60 Precision Minute & Hour Ticks
                        Repeater {
                            model: 60

                            delegate: Item {
                                id: tickItem
                                required property int index

                                anchors.fill: parent
                                rotation: tickItem.index * 6

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.topMargin: (tickItem.index % 5 === 0) ? 5 : 7
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: (tickItem.index % 15 === 0) ? 2.5 : ((tickItem.index % 5 === 0) ? 1.8 : 0.9)
                                    height: (tickItem.index % 15 === 0) ? 9 : ((tickItem.index % 5 === 0) ? 6 : 3)
                                    radius: width / 2
                                    color: (tickItem.index % 15 === 0)
                                        ? Theme.accentColour
                                        : ((tickItem.index % 5 === 0) ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.35))
                                    antialiasing: true
                                }
                            }
                        }

                        // 12 Applied Luxury Faceted Hour Markers
                        Repeater {
                            model: 12

                            delegate: Item {
                                id: markerItem
                                required property int index

                                anchors.fill: parent
                                rotation: markerItem.index * 30

                                // 12, 3, 6, 9 Double Luminous Batons
                                Row {
                                    anchors.top: parent.top
                                    anchors.topMargin: 5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    visible: markerItem.index % 3 === 0

                                    Rectangle {
                                        width: 2
                                        height: 10
                                        radius: 1
                                        color: Theme.accentColour
                                    }
                                    Rectangle {
                                        width: 2
                                        height: 10
                                        radius: 1
                                        color: Theme.accentColour
                                    }
                                }

                                // 1, 2, 4, 5, 7, 8, 10, 11 Single Faceted Batons
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.topMargin: 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: markerItem.index % 3 !== 0
                                    width: 2.2
                                    height: 8
                                    radius: 1.1
                                    color: Qt.alpha(Theme.contentColour, 0.85)
                                }
                            }
                        }

                        // Luxury Horology Inscriptions
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 48
                            text: "TITONIUM"
                            font.family: Typography.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            font.letterSpacing: 2.5
                            color: Qt.alpha(Theme.contentColour, 0.70)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 138
                            text: "CHRONOMETER"
                            font.family: Typography.fontFamily
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.8
                            color: Qt.alpha(Theme.contentColour, 0.40)
                        }

                        // ── Hands (Haute Horlogerie Handcrafted Design) ──

                        // Hour Hand (Faceted Sword Hand with Luminous Inlay)
                        Item {
                            anchors.centerIn: parent
                            width: 6
                            height: 60
                            rotation: root.hourAngle
                            transformOrigin: Item.Center

                            // Main Hand Body
                            Rectangle {
                                anchors.bottom: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 4.5
                                height: 48
                                radius: 2.25
                                color: Theme.contentColour

                                // Luminous Core
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1.8
                                    height: parent.height - 12
                                    radius: 0.9
                                    color: Qt.alpha("#ffffff", 0.90)
                                }
                            }
                        }

                        // Minute Hand (Sleek Tapered Precision Needle)
                        Item {
                            anchors.centerIn: parent
                            width: 5
                            height: 86
                            rotation: root.minuteAngle
                            transformOrigin: Item.Center

                            // Main Hand Body
                            Rectangle {
                                anchors.bottom: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 3.2
                                height: 72
                                radius: 1.6
                                color: Theme.contentColour

                                // Luminous Core
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1.4
                                    height: parent.height - 14
                                    radius: 0.7
                                    color: Qt.alpha("#ffffff", 0.90)
                                }
                            }
                        }

                        // Second Hand (Sweeping Signature Accent Needle with Counterbalance)
                        Item {
                            anchors.centerIn: parent
                            width: 3
                            height: 106
                            rotation: root.secondAngle
                            transformOrigin: Item.Center

                            // Long Pointed Needle
                            Rectangle {
                                anchors.bottom: parent.verticalCenter
                                anchors.bottomMargin: -16
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 1.4
                                height: 98
                                radius: 0.7
                                color: Theme.accentColour
                                antialiasing: true
                            }

                            // Circular Counterbalance Ring
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 5.5
                                height: 5.5
                                radius: 2.75
                                color: "transparent"
                                border.width: 1.2
                                border.color: Theme.accentColour
                            }

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Luxury Multi-Tier Center Cannon Pinion Cap
                        Rectangle {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            radius: 4
                            color: Theme.contentColour

                            Rectangle {
                                anchors.centerIn: parent
                                width: 4.5
                                height: 4.5
                                radius: 2.25
                                color: Theme.accentColour

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1.8
                                    height: 1.8
                                    radius: 0.9
                                    color: "#ffffff"
                                }
                            }
                        }
                    }
                }
            }

            // ── Digital Time & Date Display (Clean, Minimal & Modern) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Text {
                        text: Qt.formatDateTime(clock.date, "hh:mm:ss")
                        color: Theme.contentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: 22
                        font.weight: Typography.weightBold
                    }

                    // AM / PM Badge Pill
                    Rectangle {
                        implicitWidth: apText.implicitWidth + 8
                        implicitHeight: 18
                        radius: 9
                        color: Qt.alpha(Theme.accentColour, 0.20)
                        border.width: 1
                        border.color: Qt.alpha(Theme.accentColour, 0.35)

                        Text {
                            id: apText
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.date, "AP")
                            color: Theme.accentColour
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeMicro
                            font.weight: Typography.weightBold
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM, yyyy")
                    color: Qt.alpha(Theme.contentColour, 0.65)
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeBodySm
                    font.weight: Typography.weightMedium
                }
            }

            // ── Local Timezone & Region Indicator (Subtle Glass Row) ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 12
                color: Qt.alpha(Theme.contentColour, 0.05)
                border.width: 1
                border.color: Qt.alpha(Theme.contentColour, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        radius: 14
                        color: Qt.alpha(Theme.accentColour, 0.16)

                        MaterialIcon {
                            anchors.centerIn: parent
                            iconName: "schedule"
                            iconSize: 16
                            iconColour: Theme.accentColour
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("clock.timezone_title")
                            color: Theme.textPrimary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBodySm
                            font.weight: Typography.weightMedium
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.timezoneOffset + " • " + I18n.t("clock.timezone_subtitle")
                            color: Theme.textSecondary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeMicro
                            font.weight: Typography.weightNormal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // TopBar Clock Button
    Rectangle {
        id: trigger

        anchors.top: parent.top
        anchors.right: parent.right
        implicitHeight: Theme.widgetHeight
        implicitWidth: timeLabel.implicitWidth + 16
        radius: height / 2

        color: root.expanded
            ? Qt.alpha(Theme.contentColour, 0.14)
            : pointer.containsMouse
                ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.10))
                : "transparent"

        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

        Text {
            id: timeLabel
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Theme.contentColour
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            renderType: Theme.renderType
        }

        MouseArea {
            id: pointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        Accessible.role: Accessible.Button
        Accessible.name: "Clock & Timezone"
    }
}
