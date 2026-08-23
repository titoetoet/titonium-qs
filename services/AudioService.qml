pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property list<PwNode> sinks: []
    property list<PwNode> sources: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function refreshNodes(): void {
        const nextSinks = [];
        const nextSources = [];

        if (Pipewire && Pipewire.nodes && Pipewire.nodes.values) {
            for (const node of Pipewire.nodes.values) {
                if (!node || !node.ready || node.isStream || !node.audio)
                    continue;
                if (node.isSink)
                    nextSinks.push(node);
                else
                    nextSources.push(node);
            }
        }

        // Only reassign when membership changes. New array identity forces a
        // full Repeater rebuild in AudioWidget, which resets hover state and
        // makes rows feel like they are dropping mouse input.
        if (!sameIds(nextSinks, sinks))
            sinks = nextSinks;
        if (!sameIds(nextSources, sources))
            sources = nextSources;
    }

    function sameIds(next: var, current: var): bool {
        if (!next || !current || next.length !== current.length)
            return false;
        for (let i = 0; i < next.length; i++) {
            if (!next[i] || !current[i] || next[i].id !== current[i].id)
                return false;
        }
        return true;
    }

    function setVolume(value: real): void {
        if (!sink?.ready || !sink.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMuted(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function setSink(node: PwNode): void {
        if (node && node.ready)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node: PwNode): void {
        if (node && node.ready)
            Pipewire.preferredDefaultAudioSource = node;
    }

    Component.onCompleted: refreshNodes()

    Connections {
        target: Pipewire.nodes
        function onValuesChanged(): void {
            root.refreshNodes();
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources].filter(node => node && node.ready)
    }
}
