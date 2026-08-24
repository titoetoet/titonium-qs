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
                function onThemeNameChanged(): void {
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

                // 3. Subtle Inner Bezel Stroke
                context.beginPath();
                context.moveTo(edge + radius, top);
                context.lineTo(width - edge - radius, top);
                context.bezierCurveTo(width - edge - radius * (1 - bezier), top,
                                      width - edge, top + radius * (1 - bezier),
                                      width - edge, top + radius);
                context.lineTo(width - edge, height - edge - radius);
                context.bezierCurveTo(width - edge, height - edge - radius * (1 - bezier),
                                      width - edge - radius * (1 - bezier), height - edge,
                                      width - edge - radius, height - edge);
                context.lineTo(edge + radius, height - edge);
                context.bezierCurveTo(edge + radius * (1 - bezier), height - edge,
                                      edge, height - edge - radius * (1 - bezier),
                                      edge, height - edge - radius);
                context.lineTo(edge, top + radius);
                context.bezierCurveTo(edge, top + radius * (1 - bezier),
                                      edge + radius * (1 - bezier), top,
                                      edge + radius, top);
                context.closePath();
                context.lineWidth = 1;
                context.strokeStyle = Theme.themeName === "light"
                    ? "rgba(0, 0, 0, 0.08)"
                    : "rgba(255, 255, 255, 0.08)";
                context.stroke();

                // 4. Specular Neon Rim Bar (Horizontal optical refraction focal sheen along TopBar bottom edge)
                const neonGrad = context.createLinearGradient(0, top, width, top);
                if (Theme.themeName === "light") {
                    neonGrad.addColorStop(0.0, "transparent");
                    neonGrad.addColorStop(0.12, "rgba(0, 122, 255, 0.25)");
                    neonGrad.addColorStop(0.32, "rgba(50, 173, 230, 0.70)");
                    neonGrad.addColorStop(0.50, "rgba(255, 255, 255, 0.98)");
                    neonGrad.addColorStop(0.68, "rgba(50, 173, 230, 0.70)");
                    neonGrad.addColorStop(0.88, "rgba(0, 122, 255, 0.25)");
                    neonGrad.addColorStop(1.0, "transparent");
                } else {
                    neonGrad.addColorStop(0.0, "transparent");
                    neonGrad.addColorStop(0.15, "rgba(98, 114, 164, 0.35)");
                    neonGrad.addColorStop(0.40, "rgba(139, 233, 253, 0.75)");
                    neonGrad.addColorStop(0.50, "rgba(248, 248, 242, 0.90)");
                    neonGrad.addColorStop(0.60, "rgba(139, 233, 253, 0.75)");
                    neonGrad.addColorStop(0.85, "rgba(98, 114, 164, 0.35)");
                    neonGrad.addColorStop(1.0, "transparent");
                }

                context.beginPath();
                context.moveTo(edge + radius, top + 0.5);
                context.lineTo(width - edge - radius, top + 0.5);
                context.lineWidth = 1.5;
                context.strokeStyle = neonGrad;
                context.stroke();
            }
        }
    }
}
