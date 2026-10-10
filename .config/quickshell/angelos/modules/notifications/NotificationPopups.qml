pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar.win
import qs.modules.mac
import "../../widgets/Place.js" as Place

// Stack of notification cards in the top-right corner of the chosen screen. The Golden Gate skin
// has banners of its own (modules/mac/MacBanner), right under its menu bar.
PanelWindow {
    id: win

    screen: Config.notifications.screen === "primary" ? Shell.primaryScreen : Shell.screenByName(Config.notifications.screen) || Shell.focusedScreen
    // over the first-run wizard nothing pops up (they wait in the history)
    visible: Notifs.popups.length > 0 && !Shell.setupLocked
    // TrollOS: the Windows 11 layout puts toasts at the bottom right, above the taskbar
    readonly property bool winMode: Config.bar.style === "windows"
    readonly property string pos: winMode ? "bottom-right" : Config.notifications.position || "top-right"
    anchors.top: Place.top(pos)
    anchors.bottom: Place.bottom(pos)
    anchors.left: Place.left(pos)
    anchors.right: Place.right(pos)
    readonly property bool mac: GoldenGate.on
    margins.top: winMode ? 12 : mac ? GoldenGate.px(8) : Theme.u * 4
    margins.bottom: winMode ? 0 : mac ? GoldenGate.px(8) : Theme.u * 4
    margins.left: winMode ? 12 : mac ? GoldenGate.px(10) : Theme.u * 4
    margins.right: winMode ? 0 : mac ? GoldenGate.px(10) : Theme.u * 4
    implicitWidth: winMode ? 364 + 24 + 12 : mac ? GoldenGate.px(356) + GoldenGate.px(12) : Theme.u * 175
    implicitHeight: Math.max(1, winMode ? winCol.implicitHeight + 12 : col.implicitHeight + (mac ? GoldenGate.px(40) : Theme.u * 3))
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "angelos-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    // the keyboard only while a reply is being typed in a card (Enter sends it, Esc gives it back)
    WlrLayershell.keyboardFocus: Notifs.replyTo ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Golden Gate: niri blurs under each banner's rounded glass (no more than 8 stand at once)
    BackgroundEffect.blurRegion: mac ? (GoldenGate.blurOn ? macBlur : null) : Config.appearance.blur ? blurRegion : null
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
    Region {
        id: macBlur
        Region {
            item: banners.count > 0 && banners.itemAt(0) ? banners.itemAt(0).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 1 && banners.itemAt(1) ? banners.itemAt(1).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 2 && banners.itemAt(2) ? banners.itemAt(2).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 3 && banners.itemAt(3) ? banners.itemAt(3).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 4 && banners.itemAt(4) ? banners.itemAt(4).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 5 && banners.itemAt(5) ? banners.itemAt(5).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 6 && banners.itemAt(6) ? banners.itemAt(6).glassItem : null
            radius: GoldenGate.px(20)
        }
        Region {
            item: banners.count > 7 && banners.itemAt(7) ? banners.itemAt(7).glassItem : null
            radius: GoldenGate.px(20)
        }
    }

    Column {
        id: col
        visible: !win.winMode
        x: win.mac ? GoldenGate.px(6) : 0
        y: win.mac ? GoldenGate.px(6) : 0
        width: parent.width - (win.mac ? GoldenGate.px(12) : Theme.u * 3)
        spacing: win.mac ? GoldenGate.px(10) : Theme.u * 5

        Repeater {
            model: win.mac || win.winMode ? [] : Notifs.popups
            NotificationCard {
                required property var modelData
                notification: modelData
                width: col.width
            }
        }
        Repeater {
            id: banners
            model: win.mac ? Notifs.popups : []
            MacBanner {
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
