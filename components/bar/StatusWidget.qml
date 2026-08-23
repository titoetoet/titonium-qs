pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    implicitWidth: Theme.widgetHeight
    implicitHeight: Theme.widgetHeight

    Rectangle {
        anchors.centerIn: parent
        width: parent.implicitWidth
        height: Theme.widgetHeight
        radius: height / 2
        color: Qt.alpha(Theme.inputMethodIconColour, 0.16)

        Text {
            id: languageLabel

            anchors.centerIn: parent
            text: SystemStatusService.inputLanguage
            color: Theme.inputMethodIconColour
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }
}
