pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    property string newClass
    property string newWorkspace
    property bool newSilent

    // Classes of the currently open windows, to pick from
    readonly property var openClasses: [...new Set(Hyprland.toplevels.values.map(t => t.lastIpcObject?.class ?? "").filter(c => c))].sort()

    function escapeRegex(s: string): string {
        return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    title: Tr.tr("App workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Variants {
            id: classItems

            model: root.openClasses

            MenuItem {
                required property string modelData

                text: modelData
                icon: "select_window"
            }
        }

        // Rules
        SectionHeader {
            first: true
            text: Tr.tr("Rules")
        }

        InfoRow {
            first: true
            last: HyprSettings.list("appWorkspaces").length === 0
            icon: "info"
            label: Tr.tr("Windows of these apps open on the chosen workspace")
            subtext: HyprSettings.list("appWorkspaces").length === 0 ? Tr.tr("No rules yet, add one below") : Tr.tr("Switch on \"silent\" to open there without switching to it")
        }

        Repeater {
            model: HyprSettings.list("appWorkspaces")

            EntryRow {
                required property var modelData
                required property int index

                last: index === HyprSettings.list("appWorkspaces").length - 1
                icon: "move_group"
                label: modelData.class
                subtext: Tr.tr("Workspace %1%2").arg(modelData.workspace).arg(modelData.silent ? Tr.tr(", silent") : "")
                showSwitch: true
                checked: modelData.silent ?? false
                onToggled: checked => HyprSettings.updateAt("appWorkspaces", index, {
                        silent: checked
                    })
                onRemoved: HyprSettings.removeAt("appWorkspaces", index)
            }
        }

        // Add
        SectionHeader {
            text: Tr.tr("Add rule")
        }

        SelectRow {
            first: true
            label: Tr.tr("Pick an open window")
            subtext: Tr.tr("Fills in the window class below")
            menuItems: classItems.instances
            active: null
            fallbackIcon: "select_window"
            fallbackText: Tr.tr("Choose")
            onSelected: item => {
                root.newClass = root.escapeRegex(item.text);
                classField.field.text = root.newClass;
            }
        }

        TextFieldRow {
            id: classField

            label: Tr.tr("Window class")
            subtext: Tr.tr("Regex, e.g. [Ss]potify or firefox|librewolf")
            placeholderText: "firefox"
            onValueEdited: v => root.newClass = v
        }

        TextFieldRow {
            id: wsField

            label: Tr.tr("Workspace")
            subtext: Tr.tr("Number (1, 2, ...) or name:gaming")
            placeholderText: "2"
            smallField: true
            onValueEdited: v => root.newWorkspace = v
        }

        ToggleRow {
            text: Tr.tr("Silent")
            subtext: Tr.tr("Don't switch to that workspace when the app opens")
            checked: root.newSilent
            onToggled: root.newSilent = checked
        }

        RowButton {
            last: true
            icon: "add"
            text: Tr.tr("Add rule")
            subtext: root.newClass && root.newWorkspace ? Tr.tr("%1 → workspace %2").arg(root.newClass).arg(root.newWorkspace) : Tr.tr("Fill in the class and workspace first")
            disabled: !root.newClass.trim() || !root.newWorkspace.trim()
            onClicked: {
                HyprSettings.append("appWorkspaces", {
                    class: root.newClass.trim(),
                    workspace: root.newWorkspace.trim(),
                    silent: root.newSilent
                });
                root.newClass = "";
                root.newWorkspace = "";
                root.newSilent = false;
                classField.clear();
                wsField.clear();
            }
        }
    }
}
