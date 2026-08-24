pragma ComponentBehavior: Bound

import QtQuick
import "../../config"

Rectangle {
    id: root

    required property string iconName
    property int buttonSize: Theme.widgetHeight
    property string accessibleName: ""
    property bool active: false
    signal triggered

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    radius: height / 2
    color: root.active
        ? Qt.alpha(Theme.contentColour, 0.14)
        : pointer.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
            : "transparent"

    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

    MaterialIcon {
        anchors.centerIn: parent
        iconName: root.iconName
        iconSize: 19
        iconColour: Theme.contentColour
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
}
