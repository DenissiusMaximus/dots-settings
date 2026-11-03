import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common
import qs.modules.nexus.pages.hyprland

PageBase {
    id: root

    readonly property list<MenuItem> switchItems: [
        MenuItem {
            text: "Alt + Shift"
            icon: "keyboard"
            value: "grp:alt_shift_toggle"
        },
        MenuItem {
            text: "Ctrl + Shift"
            icon: "keyboard"
            value: "grp:ctrl_shift_toggle"
        },
        MenuItem {
            text: "Super + Space"
            icon: "keyboard"
            value: "grp:win_space_toggle"
        },
        MenuItem {
            text: "Caps Lock"
            icon: "keyboard_capslock"
            value: "grp:caps_toggle"
        },
        MenuItem {
            text: "Alt + Space"
            icon: "keyboard"
            value: "grp:alt_space_toggle"
        }
    ]

    // kb_options without the layout-switch (grp:...) part
    readonly property string otherOptions: HyprSettings.get("input.kbOptions", "").split(",").filter(o => o && !o.startsWith("grp:")).join(",")
    readonly property string switchOption: HyprSettings.get("input.kbOptions", "").split(",").find(o => o.startsWith("grp:")) ?? ""

    function setKbOptions(sw: string, other: string): void {
        HyprSettings.set("input.kbOptions", [sw, ...other.split(",").map(o => o.trim())].filter(o => o).join(","));
    }

    title: Tr.tr("Input")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Keyboard
        SectionHeader {
            first: true
            text: Tr.tr("Keyboard")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Keyboard layouts")
            subtext: Tr.tr("Comma separated XKB layouts, e.g. us,ua")
            value: HyprSettings.get("input.kbLayout", "us")
            onEditingFinished: v => {
                const clean = v.split(",").map(l => l.trim()).filter(l => l).join(",");
                if (clean)
                    HyprSettings.set("input.kbLayout", clean);
            }
        }

        SelectRow {
            label: Tr.tr("Switch layout with")
            subtext: Tr.tr("Key combination that cycles the layouts")
            menuItems: root.switchItems
            active: root.switchItems.find(i => i.value === root.switchOption) ?? null
            fallbackIcon: "keyboard"
            fallbackText: root.switchOption || Tr.tr("None")
            onSelected: item => root.setKbOptions(item.value, root.otherOptions)
        }

        TextFieldRow {
            label: Tr.tr("Other XKB options")
            subtext: Tr.tr("e.g. caps:escape (comma separated)")
            value: root.otherOptions
            placeholderText: "caps:escape"
            onEditingFinished: v => root.setKbOptions(root.switchOption, v)
        }

        ToggleRow {
            last: true
            text: Tr.tr("Remember layout per app")
            subtext: Tr.tr("Each window keeps its own keyboard layout")
            checked: HyprSettings.perAppLayout
            onToggled: HyprSettings.setPerAppLayout(checked)
        }

        // Mouse & touchpad
        SectionHeader {
            text: Tr.tr("Mouse & touchpad")
        }

        StepperRow {
            first: true
            label: Tr.tr("Pointer sensitivity")
            subtext: Tr.tr("From -1 (slow) to 1 (fast), 0 is the default")
            value: HyprSettings.get("input.sensitivity", 0)
            from: -1
            to: 1
            stepSize: 0.05
            onMoved: v => HyprSettings.set("input.sensitivity", Math.round(v * 100) / 100)
        }

        ToggleRow {
            text: Tr.tr("Natural scrolling")
            subtext: Tr.tr("Touchpad content moves with your fingers")
            checked: HyprSettings.get("input.naturalScroll", true)
            onToggled: HyprSettings.set("input.naturalScroll", checked)
        }

        ToggleRow {
            last: true
            text: Tr.tr("Touchpad gestures")
            subtext: Tr.tr("4 fingers: workspaces; 3 fingers: close / fullscreen / float")
            checked: HyprSettings.get("input.gestures", true)
            onToggled: HyprSettings.set("input.gestures", checked)
        }
    }
}
