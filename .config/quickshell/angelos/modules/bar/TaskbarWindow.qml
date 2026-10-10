import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Win98 taskbar at the bottom; `floating` lifts it off the edges (Compact layout).
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300
    readonly property bool floating: Config.bar.floating
    readonly property int gap: floating ? Theme.u * 4 : 0

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    margins.left: gap
    margins.right: gap
    margins.bottom: gap
    implicitHeight: Theme.u * 20 + (floating ? Theme.u * 2 : 0)
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Auto
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: box
    }

    PxBox {
        id: box
        width: parent.width - (win.floating ? Theme.u * 2 : 0)
        height: parent.height - (win.floating ? Theme.u * 2 : 0)
        color: Theme.panel
        outline: win.floating
        shadow: win.floating && Config.appearance.shadows

        Rectangle {
            // top highlight line like the original taskbar
            visible: !win.floating
            width: parent.width
            height: Theme.u
            y: -box.inset
            color: Theme.hi
        }

        BarContent {
            anchors.fill: parent
            anchors.leftMargin: Theme.u
            anchors.rightMargin: Theme.u
            screenName: win.modelData.name
            barWindow: win
            style: "taskbar"
            compact: win.compact
            itemHeight: Theme.u * 15
        }
    }

    RightClickGuard {}
}
