pragma Singleton

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property string activeSsid: ""
    property ListModel networks: ListModel {}
    property bool loading: false
    property bool polling: false
    property bool rescan: false

    function refresh(fullScan = false): void {
        if (!radioQuery.running)
            radioQuery.running = true;
        if (!networkQuery.running) {
            root.rescan = fullScan;
            root.loading = true;
            networkQuery.running = true;
        }
    }

    function toggleEnabled(): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "off" : "on"]);
        refreshTimer.restart();
    }

    function connect(ssid: string): void {
        if (!ssid)
            return;

        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
        refreshTimer.restart();
    }

    // nmcli -t escapes ':' as '\:' in field values, and '\' as '\\'
    // This parser correctly splits on unescaped ':' delimiters
    function parseTerseFields(line: string): var {
        const fields = [];
        let current = "";
        let i = 0;
        while (i < line.length) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length) {
                current += line[i + 1];
                i += 2;
            } else if (ch === ":") {
                fields.push(current);
                current = "";
                i++;
            } else {
                current += ch;
                i++;
            }
        }
        fields.push(current);
        return fields;
    }

    // Merge scan results into the ListModel using incremental edits.
    // Existing rows are never moved — signal jitter between scans would
    // otherwise reorder the list every 15s and drop the hovered row.
    // New SSIDs append at the end; setProperty updates fields in place.
    function syncNetworks(parsed: var): void {
        // Drop rows whose SSID left the list.
        for (let i = root.networks.count - 1; i >= 0; i--) {
            const ssid = root.networks.get(i).ssid;
            if (!parsed.some(n => n.ssid === ssid))
                root.networks.remove(i);
        }

        // Update existing rows in place — delegates stay alive.
        for (let ci = 0; ci < root.networks.count; ci++) {
            const cur = root.networks.get(ci);
            const p = parsed.find(n => n.ssid === cur.ssid);
            if (p) {
                root.networks.setProperty(ci, "strength", p.signal);
                root.networks.setProperty(ci, "active", p.active);
                root.networks.setProperty(ci, "security", p.security);
            }
        }

        // Insert new SSIDs before the first existing row that is weaker.
        // Existing rows are never moved, so order stays stable while new
        // networks still land near their signal rank.
        for (let ni = 0; ni < parsed.length; ni++) {
            const p = parsed[ni];
            let exists = false;
            for (let ci = 0; ci < root.networks.count; ci++) {
                if (root.networks.get(ci).ssid === p.ssid) {
                    exists = true;
                    break;
                }
            }
            if (exists)
                continue;

            let insertIdx = root.networks.count;
            for (let ci = 0; ci < root.networks.count; ci++) {
                if (root.networks.get(ci).strength < p.signal) {
                    insertIdx = ci;
                    break;
                }
            }
            root.networks.insert(insertIdx, {
                ssid: p.ssid,
                strength: p.signal,
                active: p.active,
                security: p.security
            });
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: radioQuery

        command: ["nmcli", "-t", "-f", "WIFI", "general"]

        stdout: StdioCollector {
            id: radioOutput
        }

        onExited: exitCode => {
            if (exitCode === 0)
                root.enabled = radioOutput.text.trim() === "enabled";
        }
    }

    Process {
        id: networkQuery

        command: root.rescan
            ? ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
            : ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]

        stdout: StdioCollector {
            id: networkOutput
        }

        onExited: exitCode => {
            root.loading = false;

            if (exitCode !== 0)
                return;

            // Parse lines, deduplicate by SSID keeping highest signal
            const seen = {};
            networkOutput.text.trim().split("\n")
                .filter(line => line.length > 0)
                .forEach(line => {
                    const fields = root.parseTerseFields(line);
                    const ssid = fields[1] || "Hidden network";
                    const signal = Number(fields[2]) || 0;
                    const security = fields.slice(3).join(":");
                    const active = fields[0] === "yes";

                    if (!seen[ssid] || signal > seen[ssid].signal || active) {
                        seen[ssid] = { active, ssid, signal, security };
                    }
                });

            const parsedNetworks = Object.values(seen)
                .sort((a, b) => b.signal - a.signal || a.ssid.localeCompare(b.ssid));

            root.syncNetworks(parsedNetworks);

            const activeNetwork = parsedNetworks.find(n => n.active);
            root.activeSsid = activeNetwork?.ssid || "";
        }
    }

    // One-shot timer after toggle/connect to pick up state changes
    Timer {
        id: refreshTimer

        interval: 1500
        onTriggered: root.refresh(true)
    }

    // Periodic background refresh — only while the Wi-Fi dropdown is open.
    Timer {
        interval: 15000
        running: root.polling
        repeat: true
        onTriggered: root.refresh(false)
    }
}
