pragma ComponentBehavior: Bound

import QtQuick
import "../../config"

Item {
    id: root

    default property alias data: contentItem.data
    property alias radius: bgRect.radius
    property alias color: bgRect.color
    property alias border: bgRect.border
    property alias clipContent: contentItem.clip

    // Inset Background Rectangle
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 12
        color: Theme.surfaceContainerColour
        border.width: 1
        border.color: Theme.borderSubtle
    }

    // Content Container
    Item {
        id: contentItem
        anchors.fill: parent
    }
}
