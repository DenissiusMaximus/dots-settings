import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// List entry: icon, two lines of text, optional switch and a delete button
// (same look as the rows of ListEditor).
ConnectedRect {
    id: root

    property string icon
    property alias label: label.text
    property string subtext
    property bool showSwitch
    property bool checked
    property bool removable: true

    signal toggled(checked: bool)
    signal removed

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + row.anchors.margins * 2

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

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
                id: label

                Layout.fillWidth: true
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

        StyledSwitch {
            visible: root.showSwitch
            checked: root.checked
            font: Tokens.font.icon.medium
            onToggled: root.toggled(checked)
        }

        IconButton {
            visible: root.removable
            type: IconButton.Text
            isRound: true
            icon: "delete"
            inactiveOnColour: Colours.palette.m3error
            font: Tokens.font.icon.medium
            label.fill: 0
            onClicked: root.removed()
        }
    }
}
