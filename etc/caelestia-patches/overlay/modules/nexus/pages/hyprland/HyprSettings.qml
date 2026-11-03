pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Local addition (~/dotfiles, /etc/caelestia-patches/overlay): backs the Hyprland
// pages in Nexus. Values live in ~/.config/hypr/settings.json, which the Lua config
// reads through S("..."). Every change is written to disk and applied with
// `hyprctl reload` (debounced).
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`

    // ~/.config/hypr/settings.json
    property var data: ({})
    property bool loaded

    // ~/.local/state/hypr/float_memory.lua: { class: floating }
    property var floatMemory: ({})

    // ~/.config/quickshell/overview/config.json
    property var overview: ({})

    // app-keyboard-layout.service (per-app keyboard layout)
    property bool perAppLayout

    function get(path: string, fallback: var): var {
        let v = root.data;
        for (const part of path.split(".")) {
            if (v === null || typeof v !== "object")
                return fallback;
            v = v[part];
        }
        return v === undefined || v === null ? fallback : v;
    }

    function set(path: string, value: var): void {
        const copy = JSON.parse(JSON.stringify(root.data));
        const parts = path.split(".");
        let o = copy;
        for (let i = 0; i < parts.length - 1; i++) {
            if (o[parts[i]] === null || typeof o[parts[i]] !== "object")
                o[parts[i]] = {};
            o = o[parts[i]];
        }
        if (JSON.stringify(o[parts[parts.length - 1]]) === JSON.stringify(value))
            return;
        o[parts[parts.length - 1]] = value;
        root.data = copy;
        saveTimer.restart();
    }

    // Lists (appWorkspaces, monitors, autostart, binds)
    function list(path: string): var {
        const v = get(path, []);
        return Array.isArray(v) ? v : [];
    }

    function append(path: string, item: var): void {
        set(path, [...list(path), item]);
    }

    function removeAt(path: string, index: int): void {
        const l = [...list(path)];
        l.splice(index, 1);
        set(path, l);
    }

    function updateAt(path: string, index: int, changes: var): void {
        const l = JSON.parse(JSON.stringify(list(path)));
        if (index < 0 || index >= l.length)
            return;
        l[index] = Object.assign({}, l[index], changes);
        set(path, l);
    }

    // Monitor rule for an output (or a default one)
    function monitorRule(output: string): var {
        return list("monitors").find(m => m.output === output) ?? null;
    }

    function setMonitor(output: string, changes: var): void {
        const l = JSON.parse(JSON.stringify(list("monitors")));
        const idx = l.findIndex(m => m.output === output);
        if (idx < 0)
            l.push(Object.assign({
                output,
                mode: "preferred",
                position: "auto",
                scale: 1
            }, changes));
        else
            l[idx] = Object.assign(l[idx], changes);
        set("monitors", l);
    }

    // Float memory
    function setFloatMemory(cls: string, floating: var): void {
        const m = Object.assign({}, root.floatMemory);
        if (floating === null)
            delete m[cls];
        else
            m[cls] = floating;
        root.floatMemory = m;

        const keys = Object.keys(m).sort();
        const escape = s => s.replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
        floatFile.setText("return {\n" + keys.map(k => `    ["${escape(k)}"] = ${m[k] ? "true" : "false"},\n`).join("") + "}\n");
        reloadTimer.restart();
    }

    // Overview
    function overviewGet(path: string, fallback: var): var {
        let v = root.overview;
        for (const part of path.split(".")) {
            if (v === null || typeof v !== "object")
                return fallback;
            v = v[part];
        }
        return v === undefined || v === null ? fallback : v;
    }

    function overviewSet(path: string, value: var): void {
        const copy = JSON.parse(JSON.stringify(root.overview));
        const parts = path.split(".");
        let o = copy;
        for (let i = 0; i < parts.length - 1; i++) {
            if (o[parts[i]] === null || typeof o[parts[i]] !== "object")
                o[parts[i]] = {};
            o = o[parts[i]];
        }
        o[parts[parts.length - 1]] = value;
        root.overview = copy;
        overviewTimer.restart();
    }

    function setPerAppLayout(enabled: bool): void {
        root.perAppLayout = enabled;
        Quickshell.execDetached(["systemctl", "--user", enabled ? "enable" : "disable", "--now", "app-keyboard-layout.service"]);
    }

    function reloadNow(): void {
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    FileView {
        id: settingsFile

        path: `${root.configDir}/hypr/settings.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object" && JSON.stringify(parsed) !== JSON.stringify(root.data))
                    root.data = parsed;
            } catch (e) {
                console.warn("hypr settings.json: parse error", e);
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    FileView {
        id: floatFile

        path: `${root.stateDir}/hypr/float_memory.lua`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const m = {};
            const re = /\[\s*"((?:[^"\\]|\\.)*)"\s*\]\s*=\s*(true|false)/g;
            let r;
            const t = text();
            while ((r = re.exec(t)) !== null)
                m[r[1].replace(/\\(.)/g, "$1")] = r[2] === "true";
            root.floatMemory = m;
        }
    }

    FileView {
        id: overviewFile

        path: `${root.configDir}/quickshell/overview/config.json`
        printErrors: false
        onLoaded: {
            try {
                root.overview = JSON.parse(text());
            } catch (e) {
                root.overview = {};
            }
        }
    }

    Timer {
        id: saveTimer

        interval: 400
        onTriggered: {
            settingsFile.setText(JSON.stringify(root.data, null, 2) + "\n");
            reloadTimer.restart();
        }
    }

    Timer {
        id: reloadTimer

        interval: 150
        onTriggered: root.reloadNow()
    }

    Timer {
        id: overviewTimer

        interval: 600
        onTriggered: {
            overviewFile.setText(JSON.stringify(root.overview, null, 2) + "\n");
            // The overview reads its config only on start
            Quickshell.execDetached(["sh", "-c", "qs -c overview kill >/dev/null 2>&1; sleep 0.3; qs -c overview -d >/dev/null 2>&1"]);
        }
    }

    Process {
        running: true
        command: ["systemctl", "--user", "is-enabled", "app-keyboard-layout.service"]
        stdout: StdioCollector {
            onStreamFinished: root.perAppLayout = text.trim() === "enabled"
        }
    }
}
