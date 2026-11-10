pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    property string newKeys
    property string newCommand
    property string newAutostart

    // Which row is open: "bind:<id>", "custom:<n>", "auto:<name>", "autoc:<n>"
    property string expandedId

    function toggle(id: string): void {
        expandedId = expandedId === id ? "" : id;
    }

    title: Tr.tr("Shortcuts & apps")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Apps opened by the built-in shortcuts
        SectionHeader {
            first: true
            text: Tr.tr("Apps for shortcuts")
        }

        AppField {
            first: true
            label: Tr.tr("Terminal (SUPER + Enter)")
            key: "terminal"
            fallback: "kitty"
        }

        ToggleRow {
            text: Tr.tr("Terminal opens in the VS Code folder")
            subtext: Tr.tr("SUPER + Enter in VS Code starts the terminal in that window's folder")
            checked: HyprSettings.get("apps.terminalInVscodeDir", true)
            onToggled: HyprSettings.set("apps.terminalInVscodeDir", checked)
        }

        AppField {
            label: Tr.tr("File manager (SUPER + E)")
            key: "fileManager"
            fallback: "thunar"
        }

        AppField {
            label: Tr.tr("Browser (SUPER + W)")
            key: "browser"
            fallback: "firefox"
        }

        AppField {
            label: Tr.tr("Text editor (SUPER + T)")
            key: "editor"
            fallback: "gnome-text-editor --new-window"
        }

        AppField {
            last: true
            label: Tr.tr("Calculator (SUPER + C)")
            key: "calculator"
            fallback: "gnome-calculator"
        }

        // Shortcuts
        SectionHeader {
            text: Tr.tr("Shortcuts")
        }

        InfoRow {
            first: true
            icon: "info"
            last: root.expandedId === `bind:${HyprSettings.builtinBinds[0]?.id}`
            label: Tr.tr("Click a shortcut to change its keys or turn it off")
            subtext: Tr.tr("Keys are written like SUPER + SHIFT + F1")
        }

        Repeater {
            model: HyprSettings.builtinBinds

            ExpandRow {
                id: b

                required property var modelData
                required property int index
                readonly property string rowId: `bind:${modelData.id}`

                prevOpen: index > 0 && root.expandedId === `bind:${HyprSettings.builtinBinds[index - 1].id}`
                nextOpen: index < HyprSettings.builtinBinds.length - 1 ? root.expandedId === `bind:${HyprSettings.builtinBinds[index + 1].id}` : root.expandedId === "custom:0"

                text: modelData.name
                subtext: !modelData.enabled ? Tr.tr("Turned off") : modelData.changed ? Tr.tr("Changed (default: %1)").arg(HyprSettings.prettyKeys(modelData.defaultKeys, modelData.series)) : ""
                value: HyprSettings.prettyKeys(modelData.keys, modelData.series)
                dimmed: !modelData.enabled
                expanded: root.expandedId === rowId
                onClicked: root.toggle(rowId)

                ColumnLayout {
                    spacing: Tokens.spacing.extraSmall / 2
                    TextFieldRow {
                        label: b.modelData.series ? Tr.tr("Modifier keys") : Tr.tr("Keys")
                        subtext: b.modelData.series ? Tr.tr("Used together with the number keys 1…9") : Tr.tr("e.g. SUPER + K")
                        value: b.modelData.keys
                        onEditingFinished: v => {
                            const k = v.trim();
                            if (k && k !== b.modelData.keys)
                                HyprSettings.setBindOverride(b.modelData.id, {
                                    keys: k === b.modelData.defaultKeys ? "" : k
                                });
                        }
                    }

                    ToggleRow {
                        text: Tr.tr("Enabled")
                        checked: b.modelData.enabled
                        onToggled: HyprSettings.setBindOverride(b.modelData.id, {
                            enabled: checked
                        })
                    }

                    RowButton {
                        icon: "restart_alt"
                        last: true
                        text: Tr.tr("Reset to default")
                        subtext: HyprSettings.prettyKeys(b.modelData.defaultKeys, b.modelData.series)
                        disabled: !b.modelData.changed
                        onClicked: HyprSettings.setBindOverride(b.modelData.id, {
                            keys: "",
                            enabled: true
                        })
                    }
                }
            }
        }

        // Shortcuts added here: shown by their keys
        Repeater {
            model: HyprSettings.list("binds")

            ExpandRow {
                id: c

                required property var modelData
                required property int index
                readonly property string rowId: `custom:${index}`

                prevOpen: root.expandedId === (index > 0 ? `custom:${index - 1}` : `bind:${HyprSettings.builtinBinds[HyprSettings.builtinBinds.length - 1]?.id}`)
                nextOpen: root.expandedId === `custom:${index + 1}`

                icon: "keyboard_command_key"
                text: modelData.keys
                subtext: modelData.command
                expanded: root.expandedId === rowId
                onClicked: root.toggle(rowId)

                ColumnLayout {
                    spacing: Tokens.spacing.extraSmall / 2
                    TextFieldRow {
                        label: Tr.tr("Keys")
                        value: c.modelData.keys
                        onEditingFinished: v => {
                            if (v.trim() && v.trim() !== c.modelData.keys)
                                HyprSettings.updateAt("binds", c.index, {
                                    keys: v.trim()
                                });
                        }
                    }

                    WideFieldRow {
                        label: Tr.tr("Command")
                        value: c.modelData.command
                        onEditingFinished: v => {
                            if (v.trim() && v.trim() !== c.modelData.command)
                                HyprSettings.updateAt("binds", c.index, {
                                    command: v.trim()
                                });
                        }
                    }

                    RowButton {
                        icon: "delete"
                        last: true
                        text: Tr.tr("Delete shortcut")
                        iconLabel.color: Colours.palette.m3error
                        label.color: Colours.palette.m3error
                        onClicked: {
                            root.expandedId = "";
                            HyprSettings.removeAt("binds", c.index);
                        }
                    }
                }
            }
        }

        TextFieldRow {
            id: keysField

            first: root.expandedId !== "" && root.expandedId === (HyprSettings.list("binds").length ? `custom:${HyprSettings.list("binds").length - 1}` : `bind:${HyprSettings.builtinBinds[HyprSettings.builtinBinds.length - 1]?.id}`)
            label: Tr.tr("New shortcut: keys")
            placeholderText: "SUPER + B"
            onValueEdited: v => root.newKeys = v
        }

        WideFieldRow {
            id: commandField

            label: Tr.tr("New shortcut: command")
            placeholderText: "obsidian"
            onValueEdited: v => root.newCommand = v
        }

        RowButton {
            last: true
            icon: "add"
            text: Tr.tr("Add shortcut")
            subtext: root.newKeys && root.newCommand ? `${root.newKeys} → ${root.newCommand}` : Tr.tr("Fill in the keys and the command first")
            disabled: !root.newKeys.trim() || !root.newCommand.trim()
            onClicked: {
                HyprSettings.append("binds", {
                    keys: root.newKeys.trim(),
                    command: root.newCommand.trim()
                });
                root.newKeys = "";
                root.newCommand = "";
                keysField.clear();
                commandField.clear();
            }
        }

        // Autostart
        SectionHeader {
            text: Tr.tr("Autostart")
        }

        InfoRow {
            first: true
            icon: "info"
            last: root.expandedId === `auto:${HyprSettings.builtinAutostartEff[0]?.name}`
            label: Tr.tr("Commands run when Hyprland starts")
            subtext: Tr.tr("Click one to change or turn it off; takes effect on the next login")
        }

        Repeater {
            model: HyprSettings.builtinAutostartEff

            ExpandRow {
                id: a

                required property var modelData
                required property int index
                readonly property string rowId: `auto:${modelData.name}`

                prevOpen: index > 0 && root.expandedId === `auto:${HyprSettings.builtinAutostartEff[index - 1].name}`
                nextOpen: index < HyprSettings.builtinAutostartEff.length - 1 ? root.expandedId === `auto:${HyprSettings.builtinAutostartEff[index + 1].name}` : root.expandedId === "autoc:0"

                icon: "play_circle"
                text: modelData.name
                subtext: !modelData.enabled ? Tr.tr("Turned off") : modelData.cmd
                dimmed: !modelData.enabled
                expanded: root.expandedId === rowId
                onClicked: root.toggle(rowId)

                ColumnLayout {
                    spacing: Tokens.spacing.extraSmall / 2
                    WideFieldRow {
                        label: Tr.tr("Command")
                        value: a.modelData.cmd
                        onEditingFinished: v => {
                            const cmd = v.trim();
                            if (cmd && cmd !== a.modelData.cmd)
                                HyprSettings.setAutostartOverride(a.modelData.name, {
                                    cmd: cmd === a.modelData.defaultCmd ? "" : cmd
                                });
                        }
                    }

                    ToggleRow {
                        text: Tr.tr("Run at startup")
                        checked: a.modelData.enabled
                        onToggled: HyprSettings.setAutostartOverride(a.modelData.name, {
                            enabled: checked
                        })
                    }

                    RowButton {
                        icon: "restart_alt"
                        last: true
                        text: Tr.tr("Reset to default")
                        subtext: a.modelData.defaultCmd
                        disabled: !a.modelData.changed
                        onClicked: HyprSettings.setAutostartOverride(a.modelData.name, {
                            cmd: "",
                            enabled: true
                        })
                    }
                }
            }
        }

        // Commands added here: shown as the command itself
        Repeater {
            model: HyprSettings.list("autostart")

            ExpandRow {
                id: ac

                required property var modelData
                required property int index
                readonly property string rowId: `autoc:${index}`

                prevOpen: root.expandedId === (index > 0 ? `autoc:${index - 1}` : `auto:${HyprSettings.builtinAutostartEff[HyprSettings.builtinAutostartEff.length - 1]?.name}`)
                nextOpen: root.expandedId === `autoc:${index + 1}`

                icon: "play_circle"
                text: modelData
                expanded: root.expandedId === rowId
                onClicked: root.toggle(rowId)

                ColumnLayout {
                    spacing: Tokens.spacing.extraSmall / 2
                    WideFieldRow {
                        label: Tr.tr("Command")
                        value: ac.modelData
                        onEditingFinished: v => {
                            if (v.trim() && v.trim() !== ac.modelData) {
                                const l = [...HyprSettings.list("autostart")];
                                l[ac.index] = v.trim();
                                HyprSettings.set("autostart", l);
                            }
                        }
                    }

                    RowButton {
                        icon: "delete"
                        last: true
                        text: Tr.tr("Remove from autostart")
                        iconLabel.color: Colours.palette.m3error
                        label.color: Colours.palette.m3error
                        onClicked: {
                            root.expandedId = "";
                            HyprSettings.removeAt("autostart", ac.index);
                        }
                    }
                }
            }
        }

        WideFieldRow {
            id: autostartField

            first: root.expandedId !== "" && root.expandedId === (HyprSettings.list("autostart").length ? `autoc:${HyprSettings.list("autostart").length - 1}` : `auto:${HyprSettings.builtinAutostartEff[HyprSettings.builtinAutostartEff.length - 1]?.name}`)
            label: Tr.tr("New command")
            placeholderText: "telegram-desktop"
            onValueEdited: v => root.newAutostart = v
        }

        RowButton {
            last: true
            icon: "add"
            text: Tr.tr("Add to autostart")
            disabled: !root.newAutostart.trim()
            onClicked: {
                HyprSettings.append("autostart", root.newAutostart.trim());
                root.newAutostart = "";
                autostartField.clear();
            }
        }
    }

    component AppField: WideFieldRow {
        required property string key
        required property string fallback

        value: HyprSettings.get(`apps.${key}`, fallback)

        onEditingFinished: v => {
            if (v.trim())
                HyprSettings.set(`apps.${key}`, v.trim());
        }
    }
}
