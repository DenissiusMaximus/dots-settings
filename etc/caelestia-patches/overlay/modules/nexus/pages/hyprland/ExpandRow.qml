pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// A row that opens its settings underneath when clicked
// (header: icon, title, subtitle, value on the right).
ColumnLayout {
    id: root

    property string icon
    property string text
    property string subtext
    property string value
    property bool expanded
    property bool dimmed // e.g. a turned-off shortcut
    property bool last
    // A neighbouring row is open: round the corners on that side
    property bool prevOpen
    property bool nextOpen

    // Settings shown when open; created only while open
    default property Component content

    signal clicked

    Layout.fillWidth: true
    spacing: (Tokens.spacing?.extraSmall ?? 4) / 2

    ConnectedRect {
        id: header

        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + Tokens.padding.medium * 2
        first: root.expanded || root.prevOpen
        last: (root.last && !root.expanded) || (root.nextOpen && !root.expanded)

        StateLayer {
            onClicked: root.clicked()
        }

        RowLayout {
            id: row

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.large
            spacing: Tokens.spacing.medium
            opacity: root.dimmed ? 0.5 : 1

            MaterialIcon {
                visible: root.icon
                text: root.icon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.text
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.subtext
                    text: root.subtext
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            StyledText {
                visible: root.value
                Layout.maximumWidth: root.width / 2
                text: root.value
                horizontalAlignment: Text.AlignRight
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: root.expanded ? "expand_less" : "expand_more"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        visible: active
        active: root.expanded
        sourceComponent: root.content
    }
}
