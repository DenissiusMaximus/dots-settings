//@ pragma Env QS_CRASHREPORT_URL=
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

import "modules"
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.nexus

// Only the Hyprland pages of Nexus (keys, keyboard layouts, windows, displays, shell switch),
// for when the Noctalia shell is active. Open with: qs -c nexus-lite ipc call nexus open
ShellRoot {
    settings.watchFiles: false

    GSFLoader {}

    IpcHandler {
        function open(): void {
            WindowFactory.create();
        }

        target: "nexus"
    }
}
