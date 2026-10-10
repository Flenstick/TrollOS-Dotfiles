pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.bar.win

// One bar per screen; style picks the window flavour.
Variants {
    model: Shell.screens.filter(s => !Config.bar.screens || Config.bar.screens.length === 0 || Config.bar.screens.includes(s.name))

    Scope {
        id: scope
        required property var modelData

        LazyLoader {
            active: Config.bar.style === "taskbar"
            TaskbarWindow {
                modelData: scope.modelData
            }
        }
        LazyLoader {
            active: Config.bar.style === "top"
            TopBarWindow {
                modelData: scope.modelData
            }
        }
        LazyLoader {
            active: Config.bar.style === "island"
            IslandWindow {
                modelData: scope.modelData
            }
        }
        LazyLoader {
            active: Config.bar.style === "windows"
            WinTaskbar {
                modelData: scope.modelData
            }
        }
        // macOS / Ubuntu / elementary layouts (Settings → Раскладки)
        LazyLoader {
            active: Config.dock.enabled
            DockWindow {
                modelData: scope.modelData
            }
        }
    }
}
