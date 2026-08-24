pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../../config"

Item {
    id: root

    required property bool open
    property int closedTransformOrigin: Item.Top
    default property alias data: contentContainer.data

    // Hidden unless open or still fading out. Input is disabled the moment
    // open goes false so a closing panel never steals clicks/hover from a
    // neighbouring dropdown rendered underneath it.
    visible: open || opacity > 0
    enabled: open
    opacity: open ? 1.0 : 0.0

    // ── 1. Liquid Glass Backdrop & Dual-Depth Specular Lighting ──
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.innerRadius
        antialiasing: true
        scale: root.open ? 1.0 : 0.95
        y: root.open ? 0 : -5
        transformOrigin: root.closedTransformOrigin

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.surfaceColour }
            GradientStop { position: 1.0; color: Theme.surfaceColourBottom }
        }

        border.width: 1
        border.color: Theme.popupBorder

        layer.enabled: root.visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 32
            shadowBlur: 0.65
            shadowVerticalOffset: 8
            shadowColor: Theme.popupShadowColour
        }

        // Layer 1: Top Ambient Caustic Glow (Soft liquid glass diffusion across upper edge)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 36
            radius: background.radius - 1
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.30 : 0.12) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Layer 2: Thanh đèn giả lập (Specular Rim Sheen - Focal light reflection on top edge)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1.5
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.40 : 0.25) }
                GradientStop { position: 0.5; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.85 : 0.70) }
                GradientStop { position: 0.8; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.40 : 0.25) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: root.open ? 200 : 140
                easing.type: root.open ? Easing.OutBack : Easing.OutQuad
                easing.overshoot: 1.08
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.open ? 200 : 140
                easing.type: root.open ? Easing.OutBack : Easing.OutQuad
                easing.overshoot: 1.08
            }
        }
    }

    // ── 2. Content Container (Always 1:1 pixel-perfect, native subpixel font rendering) ────
    Item {
        id: contentContainer
        anchors.fill: parent
        y: background.y
        scale: background.scale
        transformOrigin: background.transformOrigin
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.open ? 180 : 140
            easing.type: Easing.OutQuad
        }
    }
}
