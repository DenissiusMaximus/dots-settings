import QtQuick
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property bool open
    readonly property real sliderHeight: 140
    readonly property bool hovered: btn.containsMouse || catcher.containsMouse || slider.dragging

    function step(e: var): void {
        slider.setLevel(slider.level + (e.angleDelta.y > 0 ? 0.05 : -0.05));
    }

    onVisibleChanged: {
        if (!visible)
            open = false;
    }

    Timer {
        interval: 150
        running: root.visible && !root.open && btn.containsMouse
        onTriggered: root.open = true
    }

    Timer {
        interval: 400
        running: root.open && !root.hovered
        onTriggered: root.open = false
    }

    visible: slider.supported
    implicitWidth: btn.implicitWidth * 0.9
    implicitHeight: btn.implicitHeight * 0.9

    BlobGroup {
        id: blobGroup

        color: Colours.palette.m3surfaceContainerHighest
        smoothing: root.Tokens.rounding.medium
        cornerFill: false

        Behavior on color {
            CAnim {}
        }
    }

    BlobRect {
        id: btnRect

        anchors.fill: parent
        anchors.margins: !btn.pressed && btn.containsMouse ? -Tokens.padding.extraSmall : 0
        group: blobGroup
        radius: Tokens.rounding.medium

        Behavior on anchors.margins {
            Anim {}
        }
    }

    BlobRect {
        id: rect

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: Tokens.rounding.medium
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                rect.anchors.topMargin: -root.Tokens.padding.extraSmall
                rect.implicitWidth: root.width + root.Tokens.padding.extraSmall * 2
                rect.implicitHeight: root.height + root.Tokens.spacing.small + root.sliderHeight + root.Tokens.padding.medium
                content.opacity: 1
            }
        }

        transitions: Transition {
            Anim {
                properties: "implicitWidth"
            }
            Anim {
                properties: "topMargin,implicitHeight"
                easing: root.Tokens.anim.expressiveFastSpatial
            }
            Anim {
                property: "opacity"
                type: Anim.DefaultEffects
            }
        }

        Behavior on implicitWidth {
            Anim {}
        }

        Behavior on implicitHeight {
            Anim {}
        }

        MouseArea { // Swallows clicks and wheel so they don't reach the lyrics below
            id: catcher

            anchors.fill: parent
            enabled: root.open
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: e => root.step(e)
        }

        Item {
            id: content

            anchors.fill: parent
            clip: true
            opacity: 0

            VolumeSlider {
                id: slider

                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.medium
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: root.sliderHeight
                showValueLabel: false
                handleWidth: 22
                handlePressedWidth: 26
                enabled: root.open
            }
        }
    }

    MouseArea {
        id: btn

        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: slider.toggleMute()
        onWheel: e => root.step(e)

        MaterialIcon {
            id: icon

            readonly property bool showValue: root.open || slider.changing

            anchors.centerIn: parent
            text: slider.level <= 0 ? "no_sound" : slider.level < 0.5 ? "volume_down" : "volume_up"
            fontStyle: Tokens.font.icon.medium
            opacity: showValue ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: Math.round(slider.level * 100)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            opacity: icon.showValue ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
