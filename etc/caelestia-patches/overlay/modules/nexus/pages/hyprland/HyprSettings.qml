pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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

    // Built-in shortcuts from the DESC table of binds.lua: [{ id, name }]
    property var bindDefs: []
    // Same, with the overrides from settings.json applied
    readonly property var builtinBinds: {
        const ov = get("bindOverrides", {});
        return bindDefs.map(d => {
            const o = ov[d.id] ?? {};
            const series = / \+ N$/.test(d.id);
            const defKeys = series ? d.id.slice(0, -4) : d.id;
            return {
                id: d.id,
                name: d.name,
                series,
                defaultKeys: defKeys,
                keys: o.keys || defKeys,
                enabled: o.enabled !== false,
                changed: !!(o.keys || o.enabled === false)
            };
        });
    }

    // Built-in autostart entries from ~/.config/hypr/config/autostart.lua: [{ name, cmd }]
    property var builtinAutostart: []

    readonly property var modNames: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]
    readonly property var keyNames: ({
            "Return": "Enter",
            "period": ".",
            "Minus": "−",
            "Plus": "+",
            "Escape": "Esc",
            "Space": "Space",
            "Print": "Print",
            "mouse:272": "Left mouse button",
            "mouse:273": "Right mouse button",
            "mouse_up": "Scroll up",
            "mouse_down": "Scroll down",
            "code:82": "Keypad −",
            "code:86": "Keypad +",
            "Left": "←",
            "Right": "→",
            "Up": "↑",
            "Down": "↓",
            "XF86AudioRaiseVolume": "Volume up key",
            "XF86AudioLowerVolume": "Volume down key",
            "XF86AudioMute": "Mute key",
            "XF86AudioMicMute": "Mic mute key",
            "XF86AudioPlay": "Play key",
            "XF86AudioPause": "Pause key",
            "XF86AudioNext": "Next track key",
            "XF86AudioPrev": "Previous track key",
            "XF86MonBrightnessUp": "Brightness up key",
            "XF86MonBrightnessDown": "Brightness down key",
            "XF86Calculator": "Calculator key"
        })

    function keyLabel(key: string): string {
        const m = key.match(/^code:(\d+)$/);
        if (m && +m[1] >= 10 && +m[1] <= 19)
            return String((+m[1] - 9) % 10);
        return root.keyNames[key] ?? (key.length === 1 ? key.toUpperCase() : key);
    }

    function comboLabel(modmask: int, key: string, keycode: int): string {
        const parts = root.modNames.filter(m => modmask & m[0]).map(m => m[1]);
        parts.push(keyLabel(key || (keycode ? `code:${keycode}` : "?")));
        return parts.join(" + ");
    }

    // "SUPER + 1", "SUPER + 2", ... "SUPER + 9" -> "SUPER + 1…9"
    function keysLabel(keys: var): string {
        if (keys.length > 2) {
            const prefix = k => k.slice(0, k.lastIndexOf(" + ") + 3);
            const p = prefix(keys[0]);
            if (keys.every(k => prefix(k) === p))
                return `${p}${keys[0].slice(p.length)}…${keys[keys.length - 1].slice(p.length)}`;
        }
        return keys.join("  /  ");
    }

    // Pretty form of a combination string: "SUPER + CONTROL + code:82" -> "SUPER + CTRL + Keypad −"
    function prettyKeys(keys: string, series: bool): string {
        const parts = keys.split("+").map(k => k.trim()).filter(k => k).map(k => {
            const u = k.toUpperCase();
            if (u === "CONTROL" || u === "CTRL")
                return "CTRL";
            if (["SUPER", "ALT", "SHIFT"].includes(u))
                return u;
            return keyLabel(k);
        });
        if (series)
            parts.push("1…9");
        return parts.join(" + ");
    }

    function setBindOverride(id: string, changes: var): void {
        const ov = JSON.parse(JSON.stringify(get("bindOverrides", {})));
        const o = Object.assign(ov[id] ?? {}, changes);
        if (o.enabled !== false)
            delete o.enabled;
        if (!o.keys)
            delete o.keys;
        if (Object.keys(o).length)
            ov[id] = o;
        else
            delete ov[id];
        set("bindOverrides", ov);
    }

    // Built-in autostart entries with overrides applied
    readonly property var builtinAutostartEff: {
        const ov = get("autostartOverrides", {});
        return builtinAutostart.map(a => {
            const o = ov[a.name] ?? {};
            return {
                name: a.name,
                defaultCmd: a.cmd,
                cmd: o.cmd || a.cmd,
                enabled: o.enabled !== false,
                changed: !!(o.cmd || o.enabled === false)
            };
        });
    }

    function setAutostartOverride(name: string, changes: var): void {
        const ov = JSON.parse(JSON.stringify(get("autostartOverrides", {})));
        const o = Object.assign(ov[name] ?? {}, changes);
        if (o.enabled !== false)
            delete o.enabled;
        if (!o.cmd)
            delete o.cmd;
        if (Object.keys(o).length)
            ov[name] = o;
        else
            delete ov[name];
        set("autostartOverrides", ov);
    }

    function get(path: string, fallback: var): var {
        let v = root.data;
        for (const part of path.split(".")) {
            if (v === null || typeof v !== "object")
                return fallback;
            v = v[part];
        }
        return v === undefined || v === null ? fallback : v;
    }

    // Changes made before settings.json finished loading
    property var pending: []

    function set(path: string, value: var): void {
        if (!root.loaded) {
            root.pending = [...root.pending, [path, value]];
            return;
        }
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
    function flushPending(): void {
        root.loaded = true;
        const p = root.pending;
        root.pending = [];
        for (const [path, value] of p)
            set(path, value);
    }

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
            root.flushPending();
        }
        onLoadFailed: root.flushPending()
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

    // DESC table of ~/.config/hypr/config/binds.lua: ["SUPER + Q"] = "Close window"
    FileView {
        path: `${root.configDir}/hypr/config/binds.lua`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const t = text();
            const start = t.indexOf("local DESC = {");
            const end = t.indexOf("\n}", start);
            if (start < 0 || end < 0)
                return;
            const out = [];
            const re = /\[\s*"([^"]+)"\s*\]\s*=\s*"((?:[^"\\]|\\.)*)"/g;
            const block = t.slice(start, end);
            let r;
            while ((r = re.exec(block)) !== null)
                out.push({
                    id: r[1],
                    name: r[2].replace(/\\(.)/g, "$1")
                });
            root.bindDefs = out;
        }
    }

    FileView {
        path: `${root.configDir}/hypr/config/autostart.lua`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const out = [];
            const re = /\{\s*name\s*=\s*"((?:[^"\\]|\\.)*)"\s*,\s*cmd\s*=\s*"((?:[^"\\]|\\.)*)"\s*\}/g;
            let r;
            const t = text();
            while ((r = re.exec(t)) !== null)
                out.push({
                    name: r[1].replace(/\\(.)/g, "$1"),
                    cmd: r[2].replace(/\\(.)/g, "$1")
                });
            root.builtinAutostart = out;
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
