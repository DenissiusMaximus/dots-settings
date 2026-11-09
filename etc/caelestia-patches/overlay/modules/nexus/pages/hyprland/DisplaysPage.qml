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

    readonly property list<MenuItem> vrrItems: [
        MenuItem {
            text: Tr.trCtx("Off", "variable refresh rate")
            icon: "block"
            value: 0
        },
        MenuItem {
            text: Tr.trCtx("Always", "variable refresh rate")
            icon: "sync"
            value: 1
        },
        MenuItem {
            text: Tr.trCtx("Fullscreen", "variable refresh rate")
            icon: "fullscreen"
            value: 2
        },
        MenuItem {
            text: Tr.trCtx("Fullscreen games & video", "variable refresh rate")
            icon: "sports_esports"
            value: 3
        }
    ]

    readonly property list<MenuItem> shellItems: [
        MenuItem {
            text: "Caelestia"
            icon: "auto_awesome"
            value: "caelestia"
        },
        MenuItem {
            text: "Noctalia"
            icon: "bedtime"
            value: "noctalia"
        }
    ]

    title: Tr.tr("Displays & system")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Repeater {
            model: Hyprland.monitors.values

            MonitorSection {}
        }

        // System
        SectionHeader {
            text: Tr.tr("System")
        }

        SelectRow {
            first: true
            label: Tr.tr("Desktop shell")
            subtext: Tr.tr("Bar, launcher, notifications and its own settings. The shell is restarted when you switch")
            menuItems: root.shellItems
            active: root.shellItems.find(i => i.value === HyprSettings.get("shell", "caelestia")) ?? root.shellItems[0]
            onSelected: item => {
                if (item.value !== HyprSettings.get("shell", "caelestia"))
                    Quickshell.execDetached([`${HyprSettings.configDir}/hypr/scripts/shell-ctl.sh`, "switch", item.value]);
            }
        }

        SelectRow {
            label: Tr.tr("Variable refresh rate")
            subtext: Tr.tr("Adaptive sync (FreeSync / G-Sync)")
            menuItems: root.vrrItems
            active: root.vrrItems.find(i => i.value === HyprSettings.get("misc.vrr", 0)) ?? root.vrrItems[0]
            onSelected: item => HyprSettings.set("misc.vrr", item.value)
        }

        ToggleRow {
            text: Tr.tr("Window swallowing")
            subtext: Tr.tr("A terminal hides while an app it launched is open")
            checked: HyprSettings.get("misc.swallow", true)
            onToggled: HyprSettings.set("misc.swallow", checked)
        }

        ToggleRow {
            last: true
            text: Tr.tr("Middle click paste")
            subtext: Tr.tr("Paste the selection with the middle mouse button")
            checked: HyprSettings.get("misc.middleClickPaste", false)
            onToggled: HyprSettings.set("misc.middleClickPaste", checked)
        }
    }

    component MonitorSection: ColumnLayout {
        id: section

        required property HyprlandMonitor modelData
        required property int index
        readonly property var ipc: modelData.lastIpcObject ?? ({})
        readonly property var rule: HyprSettings.monitorRule(modelData.name)
        readonly property list<string> scales: ["1", "1.25", "1.333333", "1.5", "1.6", "1.666667", "1.75", "2", "2.5", "3"]

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        Variants {
            id: modeItems

            model: ["preferred", "highres", "highrr", ...new Set(section.ipc.availableModes ?? [])]

            MenuItem {
                required property string modelData

                text: modelData === "preferred" ? Tr.tr("Preferred") : modelData === "highres" ? Tr.tr("Highest resolution") : modelData === "highrr" ? Tr.tr("Highest refresh rate") : modelData.replace(/(\.\d\d)Hz$/, " Hz").replace("@", " @ ")
                icon: modelData.startsWith("high") || modelData === "preferred" ? "auto_awesome" : "aspect_ratio"
                value: modelData.replace(/Hz$/, "")
            }
        }

        Variants {
            id: scaleItems

            model: section.scales

            MenuItem {
                required property string modelData

                text: `${Math.round(parseFloat(modelData) * 100)}%`
                icon: "zoom_in"
                value: parseFloat(modelData)
            }
        }

        SectionHeader {
            first: section.index === 0
            text: section.ipc.description ? `${section.modelData.name} · ${section.ipc.description}` : section.modelData.name
        }

        InfoRow {
            first: true
            icon: "monitor"
            label: Tr.tr("Current mode")
            value: `${section.modelData.width}×${section.modelData.height} @ ${Math.round(section.ipc.refreshRate ?? 0)} Hz, ${Math.round(section.modelData.scale * 100)}%`
        }

        SelectRow {
            label: Tr.tr("Resolution & refresh rate")
            subtext: Tr.tr("Saved for this monitor")
            menuItems: modeItems.instances
            active: modeItems.instances.find(i => i.value === (section.rule?.mode ?? "preferred")) ?? null
            fallbackIcon: "aspect_ratio"
            fallbackText: section.rule?.mode ?? Tr.tr("Preferred")
            onSelected: item => HyprSettings.setMonitor(section.modelData.name, {
                    mode: item.value
                })
        }

        SelectRow {
            last: true
            label: Tr.tr("Scale")
            subtext: Tr.tr("Size of everything on this monitor")
            menuItems: scaleItems.instances
            active: scaleItems.instances.find(i => Math.abs(i.value - (section.rule?.scale ?? 1)) < 0.001) ?? null
            fallbackIcon: "zoom_in"
            fallbackText: `${Math.round((section.rule?.scale ?? 1) * 100)}%`
            onSelected: item => HyprSettings.setMonitor(section.modelData.name, {
                    scale: item.value
                })
        }
    }
}
