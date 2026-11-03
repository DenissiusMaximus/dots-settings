pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    property string newKeys
    property string newCommand
    property string newAutostart

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
            label: Tr.tr("All key combinations")
            subtext: Tr.tr("Built-in ones are listed by name, the ones you add by their keys")
        }

        Repeater {
            model: HyprSettings.builtinBinds

            InfoRow {
                required property var modelData

                label: modelData.name
                value: modelData.keys
            }
        }

        Repeater {
            model: HyprSettings.list("binds")

            EntryRow {
                required property var modelData
                required property int index

                icon: "keyboard_command_key"
                label: modelData.keys
                subtext: modelData.command
                onRemoved: HyprSettings.removeAt("binds", index)
            }
        }

        TextFieldRow {
            id: keysField

            label: Tr.tr("Keys")
            placeholderText: "SUPER + B"
            onValueEdited: v => root.newKeys = v
        }

        WideFieldRow {
            id: commandField

            label: Tr.tr("Command")
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
            label: Tr.tr("Commands run when Hyprland starts")
            subtext: Tr.tr("Built-in ones are listed by name; new ones take effect on the next login")
        }

        Repeater {
            model: HyprSettings.builtinAutostart

            InfoRow {
                required property var modelData

                icon: "play_circle"
                label: modelData.name
                subtext: modelData.cmd
            }
        }

        Repeater {
            model: HyprSettings.list("autostart")

            EntryRow {
                required property var modelData
                required property int index

                icon: "play_circle"
                label: modelData
                onRemoved: HyprSettings.removeAt("autostart", index)
            }
        }

        WideFieldRow {
            id: autostartField

            label: Tr.tr("Command")
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
