pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// angelOS settings: a real toplevel window with a client-drawn NGO frame.
FloatingWindow {
    id: win

    title: Shell.appTitle + " · " + I18n.t("Настройки", "Settings")
    visible: Shell.settingsOpen
    color: "transparent"
    implicitWidth: 1040
    implicitHeight: 740
    minimumSize: Qt.size(720, 480)
    onClosed: Shell.settingsOpen = false
    onVisibleChanged: if (!visible)
        Shell.settingsOpen = false

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
    }

    RightClickGuard {}
}
