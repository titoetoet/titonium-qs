pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property var sinks: []
    property var sources: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int currentSinkId: sink?.id ?? -1
    readonly property int currentSourceId: source?.id ?? -1

    function refreshNodes(): void {
        const nextSinks = [];
        const nextSources = [];

        try {
            if (Pipewire && Pipewire.nodes && Pipewire.nodes.values) {
                const vals = Pipewire.nodes.values;
                for (let i = 0; i < vals.length; i++) {
                    const node = vals[i];
                    if (!node || node.isStream || !node.audio)
                        continue;
                    const desc = (node.description || node.name || (node.isSink ? "Output Device" : "Input Device")) + "";
                    const item = {
                        id: node.id,
                        name: (node.name || "") + "",
                        description: desc,
                        isSink: Boolean(node.isSink)
                    };
                    if (node.isSink)
                        nextSinks.push(item);
                    else
                        nextSources.push(item);
                }
            }
        } catch (e) {}

        sinks = nextSinks;
        sources = nextSources;
    }

    function setVolume(value: real): void {
        if (!sink || !sink.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMuted(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function setSink(target: var): void {
        if (!target) return;
        const targetId = (typeof target === "object" && target.id !== undefined) ? target.id : target;
        try {
            if (Pipewire && Pipewire.nodes && Pipewire.nodes.values) {
                const vals = Pipewire.nodes.values;
                for (let i = 0; i < vals.length; i++) {
                    const node = vals[i];
                    if (node && node.id === targetId) {
                        Pipewire.preferredDefaultAudioSink = node;
                        break;
                    }
                }
            }
        } catch (e) {}
    }

    function setSource(target: var): void {
        if (!target) return;
        const targetId = (typeof target === "object" && target.id !== undefined) ? target.id : target;
        try {
            if (Pipewire && Pipewire.nodes && Pipewire.nodes.values) {
                const vals = Pipewire.nodes.values;
                for (let i = 0; i < vals.length; i++) {
                    const node = vals[i];
                    if (node && node.id === targetId) {
                        Pipewire.preferredDefaultAudioSource = node;
                        break;
                    }
                }
            }
        } catch (e) {}
    }

    Component.onCompleted: refreshNodes()

    Connections {
        target: Pipewire.nodes
        function onValuesChanged(): void {
            root.refreshNodes();
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node !== null && node !== undefined)
    }
}
