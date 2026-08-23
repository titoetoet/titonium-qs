pragma ComponentBehavior: Bound

import QtQuick

Text {
    required property string iconName
    property int iconSize: 28
    property real fill: 1
    property color iconColour: "white"

    text: iconName
    color: iconColour
    font.family: "Material Symbols Rounded"
    font.pixelSize: iconSize
    font.weight: Font.Normal
    font.variableAxes: ({
        "FILL": fill,
        "GRAD": -25,
        "opsz": iconSize,
        "wght": 500
    })
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
