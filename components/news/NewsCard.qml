pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../primitives"
import "../../services"

Rectangle {
    id: root

    required property string headline
    required property string source
    required property string time
    required property color accent
    required property string link
    property string snippet: ""

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 16
    radius: 8
    color: cardMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent"

    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

    RowLayout {
        id: mainRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 10

        // Minimal Accent Bead
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
            width: 3.5
            height: 18
            radius: 1.75
            color: root.accent
        }

        ColumnLayout {
            id: col
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.headline
                color: cardMouse.containsMouse ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.90)
                font.family: Typography.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                lineHeight: 1.2

                Behavior on color { ColorAnimation { duration: Metrics.animFast } }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.source
                    color: root.accent
                    font.family: Typography.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "·"
                    color: Qt.alpha(Theme.contentColour, 0.35)
                    font.pixelSize: 10
                }

                Text {
                    text: root.time
                    color: Qt.alpha(Theme.contentColour, 0.45)
                    font.family: Typography.fontFamily
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                MaterialIcon {
                    visible: cardMouse.containsMouse
                    iconName: "open_in_new"
                    iconSize: 12
                    iconColour: Qt.alpha(Theme.contentColour, 0.60)
                }
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.link)
                NewsService.openArticle(root.link);
        }
    }
}

