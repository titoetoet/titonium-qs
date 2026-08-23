pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData

        screen: modelData

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "titonium-frame"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom

        Canvas {
            id: frameCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Immediate
            renderTarget: Canvas.Image

            Connections {
                target: Theme
                function onBarSurfaceColourChanged(): void {
                    frameCanvas.requestPaint();
                }
            }

            onWidthChanged: Qt.callLater(requestPaint)
            onHeightChanged: Qt.callLater(requestPaint)

            onPaint: {
                const context = getContext("2d");
                const edge = Theme.borderThickness;
                const top = Theme.barHeight;
                const radius = Theme.innerRadius;
                const bezier = Theme.circleBezier;

                context.reset();
                context.clearRect(0, 0, width, height);
                context.fillStyle = Theme.barSurfaceColour.toString();

                context.beginPath();

                // 1. Outer screen bounds (clockwise)
                context.moveTo(0, 0);
                context.lineTo(width, 0);
                context.lineTo(width, height);
                context.lineTo(0, height);
                context.closePath();

                // 2. Inner screen window cutout (counter-clockwise)
                context.moveTo(edge + radius, top);
                context.bezierCurveTo(edge + radius * (1 - bezier), top,
                                      edge, top + radius * (1 - bezier),
                                      edge, top + radius);
                context.lineTo(edge, height - edge - radius);
                context.bezierCurveTo(edge, height - edge - radius * (1 - bezier),
                                      edge + radius * (1 - bezier), height - edge,
                                      edge + radius, height - edge);
                context.lineTo(width - edge - radius, height - edge);
                context.bezierCurveTo(width - edge - radius * (1 - bezier), height - edge,
                                      width - edge, height - edge - radius * (1 - bezier),
                                      width - edge, height - edge - radius);
                context.lineTo(width - edge, top + radius);
                context.bezierCurveTo(width - edge, top + radius * (1 - bezier),
                                      width - edge - radius * (1 - bezier), top,
                                      width - edge - radius, top);
                context.lineTo(edge + radius, top);
                context.closePath();

                context.fill("evenodd");
            }
        }
    }
}
