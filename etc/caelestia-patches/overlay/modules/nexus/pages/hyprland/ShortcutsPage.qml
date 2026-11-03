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

        // Custom shortcuts
        SectionHeader {
            text: Tr.tr("Custom shortcuts")
        }

        InfoRow {
            first: true
            icon: "info"
            label: Tr.tr("Run a command with a key combination")
            subtext: Tr.tr("Keys like SUPER + B or SUPER + SHIFT + F1. Built-in ones are in the dotfiles README")
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

        TextFieldRow {
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
            subtext: Tr.tr("Takes effect on the next login")
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

        TextFieldRow {
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

    component AppField: TextFieldRow {
        required property string key
        required property string fallback

        subtext: Tr.tr("Command to run")
        value: HyprSettings.get(`apps.${key}`, fallback)

        onEditingFinished: v => {
            if (v.trim())
                HyprSettings.set(`apps.${key}`, v.trim());
        }
    }
}
