pragma ComponentBehavior: Bound

import QtQuick
import "../../config"

Item {
    id: root

    required property bool expanded
    required property int collapsedWidth
    required property int surfaceWidth
    required property int surfaceHeight

    default property alias contentData: content.data
    readonly property alias inputRegion: inputArea

    readonly property int joinDepth: Theme.innerRadius
    readonly property int panelTop: Theme.barHeight
        + Theme.borderThickness
        - (Theme.barHeight - collapsedWidth) / 2

    implicitWidth: panel.visible ? surfaceWidth : collapsedWidth
    implicitHeight: panel.visible ? panelTop + panel.height : collapsedWidth

    Item {
        id: inputArea

        anchors.top: parent.top
        anchors.right: parent.right
        width: root.expanded ? root.surfaceWidth : root.collapsedWidth
        height: root.expanded
            ? root.panelTop + root.joinDepth + root.surfaceHeight
            : root.collapsedWidth
    }

    PopupPanel {
        id: panel

        open: root.expanded
        closedTransformOrigin: Item.TopRight
        anchors.right: parent.right
        y: root.panelTop
        width: root.surfaceWidth
        height: root.joinDepth + root.surfaceHeight

        Item {
            id: content

            x: 0
            y: root.joinDepth
            width: root.surfaceWidth
            height: root.surfaceHeight
        }
    }
}
