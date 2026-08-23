pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"

Rectangle {
    id: root

    required property string headline
    required property string source
    required property string time
    required property color accent
    property string snippet: ""

    Layout.fillWidth: true
    implicitHeight: snippet.length > 0 ? 92 : 64
    radius: 10
    color: Theme.surfaceContainerColour

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 9
        anchors.bottomMargin: 9
        width: 3
        radius: 2
        color: root.accent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 8
        spacing: 3

        Text {
            Layout.fillWidth: true
            text: root.headline
            color: Theme.contentColour
            font.pixelSize: 12
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.snippet.length > 0
            text: root.snippet
            color: Theme.onSurfaceVariantColour
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.source
                color: Theme.onSurfaceVariantColour
                font.pixelSize: 10
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.time
                color: Theme.onSurfaceVariantColour
                font.pixelSize: 10
            }
        }
    }
}
