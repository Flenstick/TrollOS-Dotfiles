pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar.win
import "../../widgets/Place.js" as Place

// Stack of notification cards in the top-right corner of the chosen screen.
PanelWindow {
    id: win

    screen: Shell.screenByName(Config.notifications.screen) || Shell.focusedScreen
    visible: Notifs.popups.length > 0
    // Windows copy: toasts at the bottom right, above the taskbar
    readonly property bool winMode: Config.bar.style === "windows"
    readonly property string pos: winMode ? "bottom-right" : Config.notifications.position || "top-right"
    anchors.top: Place.top(pos)
    anchors.bottom: Place.bottom(pos)
    anchors.left: Place.left(pos)
    anchors.right: Place.right(pos)
    margins.top: winMode ? 12 : Theme.u * 4
    margins.bottom: winMode ? 0 : Theme.u * 4
    margins.left: winMode ? 12 : Theme.u * 4
    margins.right: winMode ? 0 : Theme.u * 4
    implicitWidth: winMode ? 364 + 24 + 12 : Theme.u * 175
    implicitHeight: Math.max(1, winMode ? winCol.implicitHeight + 12 : col.implicitHeight + Theme.u * 3)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "angelos-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: win.winMode ? null : col
        // one rounded region per toast (up to the popup limit)
        Region {
            item: win.winMode && toasts.count > 0 && toasts.itemAt(0) ? toasts.itemAt(0).cardItem : null
            radius: 8
        }
        Region {
            item: win.winMode && toasts.count > 1 && toasts.itemAt(1) ? toasts.itemAt(1).cardItem : null
            radius: 8
        }
        Region {
            item: win.winMode && toasts.count > 2 && toasts.itemAt(2) ? toasts.itemAt(2).cardItem : null
            radius: 8
        }
        Region {
            item: win.winMode && toasts.count > 3 && toasts.itemAt(3) ? toasts.itemAt(3).cardItem : null
            radius: 8
        }
    }
    // в игре карточки (срочные) пропускают мышь насквозь — захват курсора игрой не слетает
    mask: Notifs.gaming ? noInput : null
    Region {
        id: noInput
    }

    Column {
        id: col
        visible: !win.winMode
        width: parent.width - Theme.u * 3
        spacing: Theme.u * 5

        Repeater {
            model: win.winMode ? [] : Notifs.popups
            NotificationCard {
                required property var modelData
                notification: modelData
                width: col.width
            }
        }
    }
    Column {
        id: winCol
        visible: win.winMode
        x: 12
        y: 12
        spacing: 12
        // newest at the bottom, nearest the taskbar, like Windows
        Repeater {
            id: toasts
            model: win.winMode ? Notifs.popups : []
            WinToast {
                required property var modelData
                notification: modelData
            }
        }
        Item {
            width: 1
            height: 12
        }
    }

    RightClickGuard {}
}
