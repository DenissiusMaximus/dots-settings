pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Vertical volume slider for the active media player (its own MPRIS volume,
// not the system one). Hidden when the player doesn't expose a volume.
Item {
    id: root

    readonly property var player: Players.active
    readonly property bool supported: (player?.volumeSupported ?? false) && (player?.canControl ?? false)
    readonly property bool dragging: mouse.pressed

    // Volume shown by the slider. Kept apart from player.volume so the handle
    // doesn't jump back while the player is still catching up with a drag.
    property real level
    property real pos: level
    property real lastLevel: 0.5

    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer

    function sync(): void {
        if (!mouse.pressed && !settle.running)
            level = Math.max(0, Math.min(1, player?.volume ?? 0));
    }

    function setLevel(v: real): void {
        level = Math.max(0, Math.min(1, v));
        settle.restart();
        showValue.restart();
        if (supported)
            player.volume = level;
    }

    visible: supported
    implicitWidth: 20
    implicitHeight: 96

    Component.onCompleted: sync()
    onPlayerChanged: sync()

    Connections {
        function onVolumeChanged(): void {
            root.sync();
        }

        target: root.player
    }

    Timer {
        id: settle

        interval: 400
        onTriggered: root.sync()
    }

    Timer {
        id: showValue

        interval: 900
    }

    Item {
        id: track

        readonly property real gap: Tokens.spacing.extraSmall
        readonly property real filledHeight: (height - handle.implicitHeight - gap) * root.pos

        anchors.top: parent.top
        anchors.bottom: label.top
        anchors.bottomMargin: Tokens.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: 12

        StyledRect {
            id: remaining

            anchors.top: parent.top
            anchors.bottom: handle.top
            anchors.bottomMargin: track.gap
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: parent.width * opacity
            opacity: Math.min(height, 12) / 12

            radius: Tokens.rounding.medium
            bottomLeftRadius: Tokens.rounding.extraSmall / 2
            bottomRightRadius: Tokens.rounding.extraSmall / 2
            color: root.bgColour
        }

        StyledRect {
            anchors.top: parent.top
            anchors.topMargin: 4 * remaining.opacity
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: 4 * remaining.opacity
            implicitHeight: implicitWidth
            opacity: remaining.opacity

            radius: Tokens.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handle

            anchors.bottom: filled.top
            anchors.bottomMargin: track.gap
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: mouse.pressed ? 34 : 28
            implicitHeight: 4

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        StyledRect {
            id: filled

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: parent.width
            implicitHeight: track.filledHeight

            radius: Tokens.rounding.medium
            topLeftRadius: Tokens.rounding.extraSmall / 2
            topRightRadius: Tokens.rounding.extraSmall / 2
            color: root.fgColour
        }
    }

    MouseArea {
        id: mouse

        function levelAt(y: real): real {
            const usable = track.height - handle.implicitHeight - track.gap;
            return 1 - (y - handle.implicitHeight / 2) / Math.max(1, usable);
        }

        // A bit wider than the slim track so it is easy to grab
        anchors.top: track.top
        anchors.bottom: track.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: 34

        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPressed: e => root.setLevel(levelAt(e.y))
        onPositionChanged: e => root.setLevel(levelAt(e.y))
        onWheel: e => root.setLevel(root.level + (e.angleDelta.y > 0 ? 0.05 : -0.05))
    }

    Item {
        id: label

        readonly property bool showingValue: mouse.pressed || showValue.running

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: 34
        implicitHeight: icon.implicitHeight

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: root.level <= 0 ? "no_sound" : root.level < 0.5 ? "volume_down" : "volume_up"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            opacity: label.showingValue ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.level * 100)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            opacity: label.showingValue ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        // Click the icon to mute / restore
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.level > 0) {
                    root.lastLevel = root.level;
                    root.setLevel(0);
                } else {
                    root.setLevel(root.lastLevel || 0.5);
                }
            }
        }
    }

    Behavior on pos {
        enabled: !mouse.pressed

        Anim {}
    }
}
