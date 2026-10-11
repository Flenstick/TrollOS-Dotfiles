pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// angelOS settings: a real toplevel window with a client-drawn NGO frame.
// The main window's place is Shell itself; any other window gets a SettingsNav of its own.
FloatingWindow {
    id: win

    property var nav: Shell

    // the other windows say which page they are on (the Dock, Alt+Tab, Mission Control)
    title: Shell.appTitle + " · " + I18n.t("Настройки", "Settings") + (nav === Shell || !view.currentPage ? "" : " — " + view.currentPage.label)
    visible: nav.settingsOpen
    color: "transparent"
    // TrollOS: 1040×740, but never past a small laptop screen (1280×720 at niri's scale): the
    // bottom went under the panel. niri's window rule no longer fixes the size, the window asks
    readonly property var fitScreen: Shell.focusedScreen
    implicitWidth: fitScreen ? Math.min(1040, fitScreen.width - 48) : 1040
    implicitHeight: fitScreen ? Math.min(740, fitScreen.height - 96) : 740
    minimumSize: Qt.size(720, 480)
    onClosed: nav.settingsOpen = false
    onVisibleChanged: if (!visible)
        nav.settingsOpen = false

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: view.blurItem
        radius: view.fluent ? 8 : 0
    }

    SettingsView {
        id: view
        anchors.fill: parent
        hostWindow: win
        settingsNav: win.nav
    }

    RightClickGuard {}
}
