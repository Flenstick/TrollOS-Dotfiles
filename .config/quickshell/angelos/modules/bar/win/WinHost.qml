import QtQuick
import Quickshell
import qs.config

// TrollOS: the Windows 11 layout's own windows — its Alt+Tab (niri binds it through
// cfg/win-alttab.kdl) and the edge resize — loaded only while that layout is on.
Scope {
    LazyLoader {
        active: Config.bar.style === "windows" && Config.win.altTab
        WinAltTab {}
    }
    LazyLoader {
        active: Config.bar.style === "windows" && Config.win.edgeResize
        WinResize {}
    }
}
