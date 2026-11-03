import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    title: Tr.tr("Workspaces")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Workspaces
        SectionHeader {
            first: true
            text: Tr.tr("Workspaces")
        }

        StepperRow {
            first: true
            label: Tr.tr("Workspaces per monitor")
            subtext: Tr.tr("Persistent workspaces and SUPER + CTRL + number shortcuts")
            value: HyprSettings.get("workspaces.perMonitor", 3)
            from: 1
            to: 10
            onMoved: v => HyprSettings.set("workspaces.perMonitor", Math.round(v))
        }

        NavRow {
            last: true
            icon: "move_group"
            text: Tr.tr("App workspaces")
            subtext: {
                const n = HyprSettings.list("appWorkspaces").length;
                return n ? Tr.tr("%1 rule(s): which app opens on which workspace").arg(n) : Tr.tr("Which app opens on which workspace");
            }
            onClicked: root.nState.openSubPage(1)
        }

        // Overview
        SectionHeader {
            text: Tr.tr("Overview (SUPER + Tab)")
        }

        StepperRow {
            first: true
            label: Tr.tr("Rows")
            subtext: Tr.tr("Rows of workspaces in the overview")
            value: HyprSettings.overviewGet("overview.rows", 2)
            from: 1
            to: 5
            onMoved: v => HyprSettings.overviewSet("overview.rows", Math.round(v))
        }

        StepperRow {
            label: Tr.tr("Columns")
            subtext: Tr.tr("Workspaces per row")
            value: HyprSettings.overviewGet("overview.columns", 5)
            from: 1
            to: 10
            onMoved: v => HyprSettings.overviewSet("overview.columns", Math.round(v))
        }

        StepperRow {
            label: Tr.tr("Preview size")
            subtext: Tr.tr("Size of each workspace preview (% of the screen)")
            value: Math.round(HyprSettings.overviewGet("overview.scale", 0.175) * 1000) / 10
            from: 5
            to: 50
            stepSize: 0.5
            onMoved: v => HyprSettings.overviewSet("overview.scale", Math.round(v * 10) / 1000)
        }

        ToggleRow {
            text: Tr.tr("Hide empty rows")
            checked: HyprSettings.overviewGet("overview.hideEmptyRows", true)
            onToggled: HyprSettings.overviewSet("overview.hideEmptyRows", checked)
        }

        ToggleRow {
            text: Tr.tr("Show scratchpads")
            subtext: Tr.tr("Show special workspaces in the overview")
            checked: HyprSettings.overviewGet("overview.showSpecialWorkspaces", true)
            onToggled: HyprSettings.overviewSet("overview.showSpecialWorkspaces", checked)
        }

        ToggleRow {
            text: Tr.tr("Close on focus loss")
            checked: HyprSettings.overviewGet("overview.closeOnFocusLoss", true)
            onToggled: HyprSettings.overviewSet("overview.closeOnFocusLoss", checked)
        }

        ToggleRow {
            last: true
            text: Tr.tr("Dim the background")
            checked: HyprSettings.overviewGet("overview.effects.enableBackdrop", true)
            onToggled: HyprSettings.overviewSet("overview.effects.enableBackdrop", checked)
        }
    }
}
