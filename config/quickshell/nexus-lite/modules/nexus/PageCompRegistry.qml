pragma Singleton

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.hyprland

// Trimmed copy of the caelestia PageCompRegistry: only the local Hyprland pages.
QtObject {
    id: root

    readonly property list<Component> pageComps: [
        Component {
            StackPage {
                Component {
                    WindowsPage {}
                }
            }
        },
        Component {
            StackPage {
                Component {
                    WorkspacesPage {}
                }
                Component {
                    AppWorkspaces {}
                }
            }
        },
        Component {
            StackPage {
                Component {
                    InputPage {}
                }
            }
        },
        Component {
            StackPage {
                Component {
                    DisplaysPage {}
                }
            }
        },
        Component {
            StackPage {
                Component {
                    ShortcutsPage {}
                }
            }
        }
    ]

    readonly property Component placeholderComp: Component {
        Item {
            property NexusState nState
        }
    }
}
