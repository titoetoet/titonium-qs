pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string osName: _osName
    readonly property string hostname: _hostname.length > 0 ? _hostname : "TitoX"
    readonly property string user: _user.length > 0 ? _user : "cole"
    readonly property string kernel: _kernel
    readonly property string cpuModel: _cpuModel
    readonly property string gpuModel: _gpuModel
    readonly property string shell: _shell.length > 0 ? _shell : "zsh"
    readonly property string resolution: _resolution
    readonly property int packageCount: _packageCount
    readonly property string memoryTotalText: _memoryTotalText
    readonly property string wmName: "Hyprland"
    readonly property string displayServer: "Wayland"

    property string _osName: "Arch Linux"
    property string _hostname: "TitoX"
    property string _user: "cole"
    property string _kernel: ""
    property string _cpuModel: ""
    property string _gpuModel: ""
    property string _shell: "zsh"
    property string _resolution: ""
    property int _packageCount: 0
    property string _memoryTotalText: ""

    Component.onCompleted: {
        if (osReleaseFile.text()) root.parseOsRelease(osReleaseFile.text());
        if (hostnameFile.text()) root._hostname = hostnameFile.text().trim();
        if (cpuinfoFile.text()) root.parseCpuInfo(cpuinfoFile.text());
        if (meminfoFile.text()) root.parseMemInfo(meminfoFile.text());

        kernelQuery.running = true;
        gpuQuery.running = true;
        packageQuery.running = true;
        userQuery.running = true;
        shellQuery.running = true;
        resolutionQuery.running = true;
    }

    function parseOsRelease(content: string): void {
        for (const line of content.split("\n")) {
            const trimmed = line.trim();
            if (trimmed.startsWith("PRETTY_NAME=")) {
                root._osName = trimmed.substring("PRETTY_NAME=".length).replace(/^"|"$/g, "");
                return;
            }
        }
    }

    function parseCpuInfo(content: string): void {
        for (const line of content.split("\n")) {
            const trimmed = line.trim();
            if (trimmed.startsWith("model name")) {
                const idx = trimmed.indexOf(":");
                if (idx >= 0)
                    root._cpuModel = trimmed.substring(idx + 1).trim();
                return;
            }
        }
    }

    function parseMemInfo(content: string): void {
        const match = content.match(/^MemTotal:\s+(\d+)/m);
        if (match)
            root._memoryTotalText = Math.round(Number(match[1]) / 1024 / 1024) + " GiB";
    }

    FileView {
        id: osReleaseFile
        path: "/etc/os-release"
        printErrors: false
        onTextChanged: root.parseOsRelease(text())
    }

    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        printErrors: false
        onTextChanged: root._hostname = text().trim()
    }

    FileView {
        id: cpuinfoFile
        path: "/proc/cpuinfo"
        printErrors: false
        onTextChanged: root.parseCpuInfo(text())
    }

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        printErrors: false
        onTextChanged: root.parseMemInfo(text())
    }

    Process {
        id: kernelQuery
        command: ["uname", "-r"]
        stdout: StdioCollector {
            id: kernelOutput
        }
        onExited: {
            root._kernel = kernelOutput.text.trim();
        }
    }

    Process {
        id: gpuQuery
        command: ["lspci", "-mm"]
        stdout: StdioCollector {
            id: gpuOutput
        }
        onExited: {
            for (const line of gpuOutput.text.split("\n")) {
                if (/VGA compatible controller|3D controller|Display controller/.test(line)) {
                    const matches = line.match(/"([^"]+)"/g);
                    if (matches && matches.length > 0)
                        root._gpuModel = matches[matches.length - 1].replace(/"/g, "");
                    return;
                }
            }
        }
    }

    Process {
        id: packageQuery
        command: ["pacman", "-Q"]
        stdout: StdioCollector {
            id: packageOutput
        }
        onExited: {
            root._packageCount = packageOutput.text.split("\n").filter(line => line.trim().length > 0).length;
        }
    }

    Process {
        id: userQuery
        command: ["whoami"]
        stdout: StdioCollector {
            id: userOutput
        }
        onExited: {
            const u = userOutput.text.trim();
            if (u.length > 0) root._user = u;
        }
    }

    Process {
        id: shellQuery
        command: ["sh", "-c", "basename \"$SHELL\""]
        stdout: StdioCollector {
            id: shellOutput
        }
        onExited: {
            const sh = shellOutput.text.trim();
            if (sh.length > 0) root._shell = sh;
        }
    }

    Process {
        id: resolutionQuery
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: resolutionOutput
        }
        onExited: {
            try {
                const monitors = JSON.parse(resolutionOutput.text);
                if (monitors && monitors.length > 0)
                    root._resolution = monitors[0].width + "x" + monitors[0].height;
            } catch (error) {
                root._resolution = "";
            }
        }
    }
}
