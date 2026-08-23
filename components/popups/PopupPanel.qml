pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../../config"

Rectangle {
    id: root

    required property bool open
    property int closedTransformOrigin: Item.Top

    // Hidden unless open or still fading out. Input is disabled the moment
    // open goes false so a closing panel never steals clicks/hover from a
    // neighbouring dropdown rendered underneath it.
    visible: open || opacity > 0
    enabled: open
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.94
    transformOrigin: closedTransformOrigin

    radius: Theme.innerRadius
    color: Theme.surfaceColour
    clip: true
    antialiasing: true

    border.width: 0

    layer.enabled: visible
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: Theme.popupShadowRange
        shadowBlur: 1
        shadowVerticalOffset: 2
        shadowColor: Theme.popupShadowColour
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.popupAnimationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.popupAnimationDuration
            easing.type: Easing.OutCubic
        }
    }
}
