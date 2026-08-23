pragma ComponentBehavior: Bound

import QtQuick
import "../../config"

Rectangle {
    id: root

    required property string label
    property bool checked: false
    signal triggered

    implicitHeight: 34
    implicitWidth: labelText.implicitWidth + 46 + 20
    radius: 17
    color: pointer.containsMouse
        ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
        : "transparent"
    border.width: pointer.containsMouse ? 1 : 0
    border.color: Qt.alpha(Theme.contentColour, 0.25)
    opacity: enabled ? 1 : 0.4

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.contentColour
        font.pixelSize: 12
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 20
        radius: 10
        color: root.checked ? Theme.accentColour
            : Qt.alpha(Theme.surfaceContainerColour, pointer.containsMouse ? 0.55 : 1)

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: root.checked ? Theme.surfaceColour : Theme.onSurfaceVariantColour

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animationFast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checked: root.checked
}
