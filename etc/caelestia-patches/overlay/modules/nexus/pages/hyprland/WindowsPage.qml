import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    readonly property list<MenuItem> speedItems: [
        MenuItem {
            text: Tr.tr("Very fast")
            icon: "bolt"
            value: 0.5
        },
        MenuItem {
            text: Tr.tr("Fast")
            icon: "fast_forward"
            value: 0.75
        },
        MenuItem {
            text: Tr.tr("Normal")
            icon: "play_arrow"
            value: 1
        },
        MenuItem {
            text: Tr.tr("Slow")
            icon: "slow_motion_video"
            value: 1.5
        },
        MenuItem {
            text: Tr.tr("Very slow")
            icon: "hourglass_empty"
            value: 2
        }
    ]

    title: Tr.tr("Windows & look")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Layout
        SectionHeader {
            first: true
            text: Tr.tr("Gaps & borders")
        }

        StepperRow {
            first: true
            label: Tr.tr("Gaps between windows")
            subtext: Tr.tr("Space between neighbouring windows (px)")
            value: HyprSettings.get("general.gapsIn", 2)
            from: 0
            to: 50
            onMoved: v => HyprSettings.set("general.gapsIn", Math.round(v))
        }

        StepperRow {
            label: Tr.tr("Gaps to screen edges")
            subtext: Tr.tr("Space between windows and the screen border (px)")
            value: HyprSettings.get("general.gapsOut", 4)
            from: 0
            to: 100
            onMoved: v => HyprSettings.set("general.gapsOut", Math.round(v))
        }

        StepperRow {
            label: Tr.tr("Border width")
            subtext: Tr.tr("Window border thickness (px)")
            value: HyprSettings.get("general.borderSize", 1)
            from: 0
            to: 10
            onMoved: v => HyprSettings.set("general.borderSize", Math.round(v))
        }

        ToggleRow {
            last: true
            text: Tr.tr("Resize by dragging borders")
            subtext: Tr.tr("Drag a window edge with the mouse to resize it")
            checked: HyprSettings.get("general.resizeOnBorder", true)
            onToggled: HyprSettings.set("general.resizeOnBorder", checked)
        }

        // Decoration
        SectionHeader {
            text: Tr.tr("Decoration")
        }

        StepperRow {
            first: true
            label: Tr.tr("Corner rounding")
            subtext: Tr.tr("Window corner radius (px)")
            value: HyprSettings.get("decoration.rounding", 10)
            from: 0
            to: 40
            onMoved: v => HyprSettings.set("decoration.rounding", Math.round(v))
        }

        StepperRow {
            label: Tr.tr("Active window opacity")
            subtext: Tr.tr("Opacity of the focused window (%)")
            value: Math.round(HyprSettings.get("decoration.activeOpacity", 0.95) * 100)
            from: 10
            to: 100
            stepSize: 5
            onMoved: v => HyprSettings.set("decoration.activeOpacity", Math.round(v) / 100)
        }

        StepperRow {
            label: Tr.tr("Inactive window opacity")
            subtext: Tr.tr("Opacity of unfocused windows (%)")
            value: Math.round(HyprSettings.get("decoration.inactiveOpacity", 0.85) * 100)
            from: 10
            to: 100
            stepSize: 5
            onMoved: v => HyprSettings.set("decoration.inactiveOpacity", Math.round(v) / 100)
        }

        StepperRow {
            last: true
            label: Tr.tr("Dim behind scratchpads")
            subtext: Tr.tr("How much the background darkens when a scratchpad is open (%)")
            value: Math.round(HyprSettings.get("decoration.dimSpecial", 0.3) * 100)
            from: 0
            to: 100
            stepSize: 5
            onMoved: v => HyprSettings.set("decoration.dimSpecial", Math.round(v) / 100)
        }

        // Blur
        SectionHeader {
            text: Tr.tr("Blur")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Blur")
            subtext: Tr.tr("Blur what is behind transparent windows")
            checked: HyprSettings.get("decoration.blur.enabled", true)
            onToggled: HyprSettings.set("decoration.blur.enabled", checked)
        }

        StepperRow {
            label: Tr.tr("Blur size")
            subtext: Tr.tr("Blur radius")
            value: HyprSettings.get("decoration.blur.size", 5)
            from: 1
            to: 20
            onMoved: v => HyprSettings.set("decoration.blur.size", Math.round(v))
        }

        StepperRow {
            last: true
            label: Tr.tr("Blur passes")
            subtext: Tr.tr("More passes look smoother but cost more GPU")
            value: HyprSettings.get("decoration.blur.passes", 4)
            from: 1
            to: 8
            onMoved: v => HyprSettings.set("decoration.blur.passes", Math.round(v))
        }

        // Animations
        SectionHeader {
            text: Tr.tr("Animations")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Animations")
            subtext: Tr.tr("Animate windows, workspaces and scratchpads")
            checked: HyprSettings.get("animations.enabled", true)
            onToggled: HyprSettings.set("animations.enabled", checked)
        }

        SelectRow {
            last: true
            label: Tr.tr("Animation speed")
            subtext: Tr.tr("Duration of window and workspace animations")
            menuItems: root.speedItems
            active: root.speedItems.find(i => i.value === HyprSettings.get("animations.speed", 1)) ?? root.speedItems[2]
            onSelected: item => HyprSettings.set("animations.speed", item.value)
        }

        // Floating memory
        SectionHeader {
            text: Tr.tr("Remembered floating mode")
        }

        InfoRow {
            first: true
            last: Object.keys(HyprSettings.floatMemory).length === 0
            icon: "info"
            label: Tr.tr("SUPER + H toggles floating and remembers it per app")
            subtext: Object.keys(HyprSettings.floatMemory).length === 0 ? Tr.tr("No apps remembered yet") : Tr.tr("Click the switch to change, the bin to forget")
        }

        Repeater {
            model: Object.keys(HyprSettings.floatMemory).sort()

            EntryRow {
                required property string modelData
                required property int index

                last: index === Object.keys(HyprSettings.floatMemory).length - 1
                icon: HyprSettings.floatMemory[modelData] ? "picture_in_picture" : "grid_view"
                label: modelData
                subtext: HyprSettings.floatMemory[modelData] ? Tr.tr("Opens floating") : Tr.tr("Opens tiled")
                showSwitch: true
                checked: HyprSettings.floatMemory[modelData]
                onToggled: checked => HyprSettings.setFloatMemory(modelData, checked)
                onRemoved: HyprSettings.setFloatMemory(modelData, null)
            }
        }
    }
}
