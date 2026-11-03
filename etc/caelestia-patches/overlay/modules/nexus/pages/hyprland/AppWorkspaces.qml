pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    property string newClass
    property string newWorkspace
    property bool newSilent

    // Rule being edited (-1 = none)
    property int expandedIdx: -1

    // Classes of the currently open windows, to pick from
    readonly property var openClasses: [...new Set(Hyprland.toplevels.values.map(t => t.lastIpcObject?.class ?? "").filter(c => c))].sort()

    function escapeRegex(s: string): string {
        return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    // "[Ss]potify" -> "Spotify", "firefox|librewolf" -> "firefox"
    function plainClass(cls: string): string {
        return (cls ?? "").split("|")[0].replace(/\[(.)[^\]]*\]/g, "$1").replace(/\\(.)/g, "$1").replace(/[\^$()*+?{}]/g, "");
    }

    function appFor(cls: string): var {
        const plain = plainClass(cls);
        return plain ? DesktopEntries.heuristicLookup(plain) : null;
    }

    // Readable app name for a class regex
    function appName(cls: string): string {
        const entry = appFor(cls);
        const others = (cls ?? "").split("|").length - 1;
        const name = entry?.name || plainClass(cls) || cls;
        return others > 0 ? Tr.tr("%1 + %2 more").arg(name).arg(others) : name;
    }

    function wsLabel(ws: string): string {
        const s = String(ws ?? "");
        if (s.startsWith("name:"))
            return Tr.tr("Workspace \"%1\"").arg(s.slice(5));
        if (s.startsWith("special"))
            return Tr.tr("Scratchpad %1").arg(s.split(":")[1] ?? "");
        return Tr.tr("Workspace %1").arg(s);
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

                text: root.appFor(root.escapeRegex(modelData))?.name || modelData
                icon: "select_window"
                value: modelData
            }
        }

        // Rules
        SectionHeader {
            first: true
            text: Tr.tr("Rules")
        }

        InfoRow {
            first: true
            icon: "info"
            last: HyprSettings.list("appWorkspaces").length === 0 || root.expandedIdx === 0
            label: Tr.tr("These apps always open on the chosen workspace")
            subtext: HyprSettings.list("appWorkspaces").length === 0 ? Tr.tr("No rules yet, add one below") : Tr.tr("Click a rule to change or delete it")
        }

        Repeater {
            model: HyprSettings.list("appWorkspaces")

            ColumnLayout {
                id: rule

                required property var modelData
                required property int index
                readonly property bool expanded: root.expandedIdx === index
                readonly property bool isLast: index === HyprSettings.list("appWorkspaces").length - 1

                Layout.fillWidth: true
                Layout.topMargin: expanded ? Tokens.spacing.medium : 0
                Layout.bottomMargin: expanded ? Tokens.spacing.medium : 0
                spacing: (Tokens.spacing?.extraSmall ?? 4) / 2

                Behavior on Layout.topMargin {
                    Anim {}
                }

                Behavior on Layout.bottomMargin {
                    Anim {}
                }

                RowButton {
                    id: ruleBtn

                    first: rule.expanded || root.expandedIdx === rule.index - 1
                    last: (rule.isLast && !rule.expanded) || (root.expandedIdx === rule.index + 1 && !rule.expanded)
                    icon: "apps"
                    iconLabel.color: "transparent"
                    text: root.appName(rule.modelData.class)
                    subtext: root.wsLabel(rule.modelData.workspace) + (rule.modelData.silent ? Tr.tr(" · in the background") : "")
                    trailingIcon: rule.expanded ? "expand_less" : "expand_more"
                    onClicked: root.expandedIdx = rule.expanded ? -1 : rule.index

                    // App icon in place of the material icon
                    IconImage {
                        parent: ruleBtn.iconLabel
                        anchors.centerIn: parent
                        asynchronous: true
                        implicitSize: Math.round((Tokens.font?.icon?.medium?.pointSize ?? 15) * 1.6)
                        source: Quickshell.iconPath(root.appFor(rule.modelData.class)?.icon ?? "", "application-x-executable")
                    }
                }

                // Editor
                TextFieldRow {
                    visible: rule.expanded
                    label: Tr.tr("Window class")
                    subtext: Tr.tr("Regex, several apps with | (find it with hyprctl clients)")
                    value: rule.modelData.class
                    onEditingFinished: v => {
                        if (v.trim() && v.trim() !== rule.modelData.class)
                            HyprSettings.updateAt("appWorkspaces", rule.index, {
                                class: v.trim()
                            });
                    }
                }

                TextFieldRow {
                    visible: rule.expanded
                    label: Tr.tr("Workspace")
                    subtext: Tr.tr("Number (1, 2, ...) or name:gaming")
                    value: rule.modelData.workspace
                    smallField: true
                    onEditingFinished: v => {
                        if (v.trim() && v.trim() !== String(rule.modelData.workspace))
                            HyprSettings.updateAt("appWorkspaces", rule.index, {
                                workspace: v.trim()
                            });
                    }
                }

                ToggleRow {
                    visible: rule.expanded
                    text: Tr.tr("Open in the background")
                    subtext: Tr.tr("Stay on the current workspace when the app opens")
                    checked: rule.modelData.silent ?? false
                    onToggled: HyprSettings.updateAt("appWorkspaces", rule.index, {
                        silent: checked
                    })
                }

                RowButton {
                    visible: rule.expanded
                    last: true
                    icon: "delete"
                    text: Tr.tr("Delete rule")
                    iconLabel.color: Colours.palette.m3error
                    label.color: Colours.palette.m3error
                    onClicked: {
                        root.expandedIdx = -1;
                        HyprSettings.removeAt("appWorkspaces", rule.index);
                    }
                }
            }
        }

        // Add
        SectionHeader {
            text: Tr.tr("Add rule")
        }

        SelectRow {
            first: true
            label: Tr.tr("App")
            subtext: root.newClass ? Tr.tr("Window class: %1").arg(root.newClass) : Tr.tr("Pick one of the open windows")
            menuItems: classItems.instances
            active: classItems.instances.find(i => root.escapeRegex(i.value) === root.newClass) ?? null
            fallbackIcon: "select_window"
            fallbackText: Tr.tr("Choose")
            onSelected: item => {
                root.newClass = root.escapeRegex(item.value);
                classField.field.text = root.newClass;
            }
        }

        TextFieldRow {
            id: classField

            label: Tr.tr("…or type the window class")
            subtext: Tr.tr("Regex, several apps with |")
            onValueEdited: v => root.newClass = v
        }

        TextFieldRow {
            id: wsField

            label: Tr.tr("Workspace")
            subtext: Tr.tr("Number (1, 2, ...) or name:gaming")
            smallField: true
            onValueEdited: v => root.newWorkspace = v
        }

        ToggleRow {
            text: Tr.tr("Open in the background")
            subtext: Tr.tr("Stay on the current workspace when the app opens")
            checked: root.newSilent
            onToggled: root.newSilent = checked
        }

        RowButton {
            last: true
            icon: "add"
            text: Tr.tr("Add rule")
            subtext: root.newClass.trim() && root.newWorkspace.trim() ? `${root.appName(root.newClass)} → ${root.wsLabel(root.newWorkspace.trim())}` : !root.newClass.trim() ? Tr.tr("Choose an app first") : Tr.tr("Type a workspace first")
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
