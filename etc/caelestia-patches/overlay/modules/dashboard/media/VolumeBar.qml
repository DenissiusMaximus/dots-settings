pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Volume slider for the active media player (its own MPRIS volume, not the
// system one). Hidden when the player doesn't expose a volume.
RowLayout {
    id: root

    readonly property var player: Players.active
    readonly property bool supported: (player?.volumeSupported ?? false) && (player?.canControl ?? false)

    // Volume shown by the slider. Kept apart from player.volume so the handle
    // doesn't jump back while the player is still catching up with a drag.
    property real level
    property real lastLevel: 0.5

    function sync(): void {
        if (!slider.dragging && !settle.running)
            level = Math.max(0, Math.min(1, player?.volume ?? 0));
    }

    function setLevel(v: real): void {
        level = Math.max(0, Math.min(1, v));
        settle.restart();
        if (supported)
            player.volume = level;
    }

    visible: supported
    spacing: Tokens.spacing.small

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

    // Same width as the time labels of the position slider above, so both sliders line up
    TextMetrics {
        id: sideMetrics

        text: "0:00"
        font: Tokens.font.label.medium
    }

    TextMetrics {
        id: valueMetrics

        text: "100%"
        font: sideMetrics.font
    }

    Item {
        Layout.preferredWidth: sideMetrics.width
        implicitHeight: icon.implicitHeight

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: root.level <= 0 ? "no_sound" : root.level < 0.5 ? "volume_down" : "volume_up"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
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

    StyledSlider {
        id: slider

        Layout.fillWidth: true
        value: root.level
        onInteraction: v => root.setLevel(v)

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Tokens.padding.small
            acceptedButtons: Qt.NoButton
            onWheel: e => root.setLevel(root.level + (e.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    StyledText {
        Layout.preferredWidth: Math.max(sideMetrics.width, valueMetrics.width)
        text: Math.round((slider.dragging ? slider.pos : root.level) * 100) + "%"
        color: Colours.palette.m3onSurfaceVariant
        font: sideMetrics.font
        horizontalAlignment: Text.AlignHCenter
    }
}
