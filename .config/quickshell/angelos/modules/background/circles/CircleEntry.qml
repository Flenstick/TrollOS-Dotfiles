pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// What every entry of a circle's menu look shares (modules/background/circles; heaven's
// WingsLook and HarpLook use it too): which entry it is, whether you're on it, and the mouse — hovering selects it (a flyout opens after a
// beat, RadialMenu.hoverEntry), a click runs it. The look draws it: the children go inside,
// the mouse covers the whole item.
MouseArea {
    id: entry

    required property var menu              // RadialMenu
    required property string modelData
    required property int index
    readonly property var e: DeskMenu.entry(modelData)
    readonly property bool sel: menu.current === index
    readonly property bool open: menu.fly === modelData
    readonly property bool hot: sel || open
    readonly property string label: e ? (e.short || e.label) : ""
    readonly property string icon: e ? e.icon : "heart"
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: menu.hoverEntry(index)
    onClicked: menu.activate(index)
}
