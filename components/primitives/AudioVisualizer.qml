pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    property bool active: true
    property int barCount: 40
    property real barWidth: 3
    property real barSpacing: 3
    property real minHeight: 3
    property real maxHeight: 26

    implicitWidth: barCount * barWidth + (barCount - 1) * barSpacing
    implicitHeight: maxHeight

    // 0: Bars, 1: Wave, 2: Floating Dots
    readonly property int currentMode: SettingsService.visualizerMode

    property real animPhase: 0

    NumberAnimation {
        id: phaseAnim
        target: root
        property: "animPhase"
        from: 0
        to: Math.PI * 2
        duration: 2000
        loops: Animation.Infinite
        running: root.active
    }

    onAnimPhaseChanged: {
        if (root.currentMode === 1 && waveCanvas.visible) {
            waveCanvas.requestPaint();
        }
    }

    function getSpectrumColor(ratio: real): color {
        if (ratio < 0.25) {
            const t = ratio / 0.25;
            return Qt.tint(Theme.downloadIconColour, Qt.alpha(Theme.gpuIconColour, t));
        } else if (ratio < 0.50) {
            const t = (ratio - 0.25) / 0.25;
            return Qt.tint(Theme.gpuIconColour, Qt.alpha(Theme.inputMethodIconColour, t));
        } else if (ratio < 0.75) {
            const t = (ratio - 0.50) / 0.25;
            return Qt.tint(Theme.inputMethodIconColour, Qt.alpha(Theme.accentColour, t));
        } else {
            const t = (ratio - 0.75) / 0.25;
            return Qt.tint(Theme.accentColour, Qt.alpha(Theme.cpuIconColour, t));
        }
    }

    // ── Mode 0: Spectrum Equalizer Bars ──────────────────────────────────────
    Row {
        id: barsView
        anchors.centerIn: parent
        spacing: root.barSpacing
        visible: root.currentMode === 0

        Repeater {
            model: root.barCount

            delegate: Item {
                id: barContainer
                required property int index

                width: root.barWidth
                height: root.maxHeight

                readonly property real norm: barContainer.index / Math.max(1, root.barCount - 1)
                readonly property real bassBoost: (1.0 - norm) * 0.40
                readonly property real midPeak: Math.sin(norm * Math.PI) * 0.35
                readonly property real wave: Math.sin(root.animPhase + barContainer.index * 0.35) * 0.30
                    + Math.cos(root.animPhase * 1.6 + barContainer.index * 0.60) * 0.25

                readonly property real targetHeight: root.active
                    ? Math.max(root.minHeight, Math.min(root.maxHeight, (bassBoost + midPeak + (wave + 1) * 0.25) * root.maxHeight))
                    : root.minHeight

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.barWidth
                    height: barContainer.targetHeight
                    radius: root.barWidth / 2
                    color: root.getSpectrumColor(barContainer.norm)
                }
            }
        }
    }

    // ── Mode 1: Fluid Sine Waveform (Canvas) ──────────────────────────────────
    Canvas {
        id: waveCanvas
        anchors.fill: parent
        visible: root.currentMode === 1
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            const count = root.barCount;
            const midY = height / 2;
            const step = width / (count - 1);

            const grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0.0, Theme.downloadIconColour);
            grad.addColorStop(0.4, Theme.gpuIconColour);
            grad.addColorStop(0.7, Theme.inputMethodIconColour);
            grad.addColorStop(1.0, Theme.accentColour);

            // Wave 1: Primary Upper Wave
            ctx.beginPath();
            ctx.strokeStyle = grad;
            ctx.lineWidth = 2.2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            for (let i = 0; i < count; i++) {
                const norm = i / (count - 1);
                const amp = root.active
                    ? (0.25 + 0.75 * Math.sin(norm * Math.PI)) * (midY - 2)
                    : 2;
                const x = i * step;
                const y = midY - amp * Math.sin((i / count) * Math.PI * 2 + root.animPhase);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();

            // Wave 2: Symmetrical Harmonic Lower Wave
            ctx.beginPath();
            ctx.strokeStyle = Qt.alpha(Theme.accentColour, 0.50);
            ctx.lineWidth = 1.6;

            for (let i = 0; i < count; i++) {
                const norm = i / (count - 1);
                const amp = root.active
                    ? (0.2 + 0.6 * Math.sin(norm * Math.PI)) * (midY - 3)
                    : 1.5;
                const x = i * step;
                const y = midY + amp * Math.cos((i / count) * Math.PI * 2 + root.animPhase * 1.4);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }
    }

    // ── Mode 2: Floating Pulsing Dots ─────────────────────────────────────────
    Row {
        id: dotsView
        anchors.centerIn: parent
        spacing: root.barSpacing
        visible: root.currentMode === 2

        Repeater {
            model: root.barCount

            delegate: Item {
                id: dotContainer
                required property int index

                width: root.barWidth
                height: root.maxHeight

                readonly property real norm: dotContainer.index / Math.max(1, root.barCount - 1)
                readonly property real wave: Math.sin(root.animPhase + dotContainer.index * 0.4)
                readonly property real amp: root.active ? (0.35 + 0.65 * Math.abs(wave)) : 0.2

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(2.5, root.barWidth * (0.6 + dotContainer.amp * 0.8))
                    height: width
                    radius: width / 2
                    color: root.getSpectrumColor(dotContainer.norm)
                    opacity: 0.45 + dotContainer.amp * 0.55

                    y: (root.maxHeight - height) / 2 - (dotContainer.amp * 8 * dotContainer.wave)
                }
            }
        }
    }

    // ── Interactive Mode Switcher ────────────────────────────────────────────
    MouseArea {
        id: visualizerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SettingsService.cycleVisualizerMode();
        }
    }
}
