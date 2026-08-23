pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real cpuUsage: _cpuUsage
    readonly property real gpuUsage: _gpuUsage

    readonly property string inputLanguage: _inputLanguage
    readonly property real cpuTemperature: _cpuTemperature
    readonly property real gpuTemperature: _gpuTemperature
    readonly property real memoryUsage: _memoryUsage
    readonly property real loadAverage: _loadAverage
    readonly property real uptimeSeconds: _uptimeSeconds

    readonly property bool monitoringActive: monitoringRefCount > 0
    property int monitoringRefCount: 0

    function acquireMonitoring(): void {
        monitoringRefCount++;
    }

    function releaseMonitoring(): void {
        monitoringRefCount = Math.max(0, monitoringRefCount - 1);
    }

    property real _cpuUsage: 0
    property real _gpuUsage: 0

    property string _inputLanguage: "EN"
    property real _cpuTemperature: 0
    property real _gpuTemperature: 0
    property real _memoryUsage: 0
    property real _loadAverage: 0
    property real _uptimeSeconds: 0

    property real previousCpuTotal: 0
    property real previousCpuIdle: 0

    function updateCpu(content: string): void {
        const line = content.split("\n")[0]?.trim();
        if (!line?.startsWith("cpu "))
            return;

        const fields = line.split(/\s+/).slice(1).map(value => Number(value));
        if (fields.length < 5 || fields.some(value => !Number.isFinite(value)))
            return;

        const total = fields.reduce((sum, value) => sum + value, 0);
        const idle = fields[3] + fields[4];

        if (previousCpuTotal > 0) {
            const totalDelta = total - previousCpuTotal;
            const idleDelta = idle - previousCpuIdle;
            if (totalDelta > 0)
                _cpuUsage = Math.max(0, Math.min(100, (1 - idleDelta / totalDelta) * 100));
        }

        previousCpuTotal = total;
        previousCpuIdle = idle;
    }


    function updateGpu(): void {
        const value = Number(gpuCard0.text().trim() || gpuCard1.text().trim());
        _gpuUsage = Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : 0;
    }

    function updateSystemInfo(): void {
        const values = {};
        for (const line of memoryFile.text().split("\n")) {
            const match = line.match(/^(\w+):\s+(\d+)/);
            if (match)
                values[match[1]] = Number(match[2]);
        }

        const total = values.MemTotal || 0;
        const available = values.MemAvailable || 0;
        _memoryUsage = total > 0 ? Math.max(0, Math.min(100, (1 - available / total) * 100)) : 0;

        const load = Number(loadFile.text().trim().split(/\s+/)[0]);
        _loadAverage = Number.isFinite(load) ? load : 0;

        const uptime = Number(uptimeFile.text().trim().split(/\s+/)[0]);
        _uptimeSeconds = Number.isFinite(uptime) ? uptime : 0;
    }

    function formatUptime(seconds: real): string {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return days > 0 ? days + "d " + hours + "h" : hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    // --- Files ---


    FileView {
        id: cpuFile
        path: "/proc/stat"
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
    }

    FileView {
        id: gpuCard0
        path: "/sys/class/drm/card0/device/gpu_busy_percent"
        printErrors: false
    }

    FileView {
        id: gpuCard1
        path: "/sys/class/drm/card1/device/gpu_busy_percent"
        printErrors: false
    }

    // --- Timers ---


    // CPU, GPU, RAM, Load, Uptime — chỉ poll khi dashboard đang mở
    Timer {
        interval: 1000
        running: root.monitoringActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload();
            gpuCard0.reload();
            gpuCard1.reload();
            memoryFile.reload();
            loadFile.reload();
            uptimeFile.reload();

            root.updateCpu(cpuFile.text());
            root.updateGpu();
            root.updateSystemInfo();
        }
    }

    // Nhiệt độ — chỉ poll khi dashboard đang mở, interval 5s vì thay đổi chậm
    Process {
        id: temperatureQuery
        command: ["sensors", "-j"]
        stdout: StdioCollector {
            id: temperatureOutput
        }
        onExited: {
            try {
                const data = JSON.parse(temperatureOutput.text);
                const cpuKey = Object.keys(data).find(key => key.startsWith("k10temp"));
                const gpuKey = Object.keys(data).find(key => key.startsWith("amdgpu"));

                const cpu = data[cpuKey]?.Tctl?.temp1_input;
                const gpu = data[gpuKey]?.edge?.temp1_input;

                root._cpuTemperature = Number.isFinite(cpu) ? cpu : 0;
                root._gpuTemperature = Number.isFinite(gpu) ? gpu : 0;
            } catch (error) {
                root._cpuTemperature = 0;
                root._gpuTemperature = 0;
            }
        }
    }

    Timer {
        interval: 5000
        running: root.monitoringActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!temperatureQuery.running)
                temperatureQuery.running = true;
        }
    }

    // Input language — poll mỗi 3s, luôn chạy vì hiển thị trên bar
    Process {
        id: fcitxQuery
        command: ["fcitx5-remote", "-n"]
        stdout: StdioCollector {
            id: fcitxOutput
        }
        onExited: {
            const engine = fcitxOutput.text.trim().toLowerCase();
            root._inputLanguage = engine.includes("lotus") ? "VI" : "EN";
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!fcitxQuery.running)
                fcitxQuery.running = true;
        }
    }
}
