pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The ring look of RadialMenu: the entries on a circle around the pointer, the logo in the
// middle (click closes), the hovered entry's full name above it, flyouts as a FlyColumn.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property real slotSize: Math.round(Theme.u * 22 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    // room for every slot and its name around the circle
    readonly property real r1: Math.max(Theme.u * 36 * k, menu.slots.length * (slotSize + (menu.labels ? Theme.u * 22 : Theme.u * 8)) / (2 * Math.PI))
    readonly property real r2: r1 + slotSize / 2 + labelRoom + Theme.u * 14 * k
    readonly property real reach: r1 + slotSize + labelRoom
    readonly property Item blurItem: null
    function angleOf(i) {
        return -Math.PI / 2 + i * 2 * Math.PI / Math.max(1, menu.slots.length);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // a glow behind the ring
    Rectangle {
        x: look.menu.cx - width / 2
        y: look.menu.cy - height / 2
        width: (look.r1 + look.slotSize) * 2 * Math.max(0.2, look.menu.reveal)
        height: width
        radius: width / 2
        color: Qt.alpha(Theme.accent, 0.1 * look.menu.reveal)
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha(Theme.accent, 0.25 * look.menu.reveal)
    }

    // the hub: the logo; closes
    PxBox {
        id: hub
        x: look.menu.cx - width / 2
        y: look.menu.cy - height / 2
        width: Math.round(look.slotSize * 1.15)
        height: width
        scale: look.menu.reveal
        color: hubMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.35) : Qt.alpha(Theme.menuSurface, Math.max(0.85, Theme.panelAlpha))
        shadow: Config.appearance.shadows
        AngelLogo {
            anchors.centerIn: parent
            emblemOnly: true
            pixel: Math.max(1, Math.round(Theme.u * look.k * 0.75))
        }
        MouseArea {
            id: hubMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                look.menu.current = -1;
                look.menu.fly = "";
            }
            onClicked: look.menu.close()
        }
    }
    // the hovered entry's full name above the hub
    PxBox {
        visible: !!look.menu.hoveredEntry && look.menu.reveal > 0.6
        x: look.menu.cx - width / 2
        y: look.menu.cy - hub.height / 2 - height - Theme.u * 3
        width: hoverName.implicitWidth + Theme.u * 8
        height: hoverName.implicitHeight + Theme.u * 4
        color: Qt.alpha(Theme.menuSurface, 0.92)
        PxText {
            id: hoverName
            anchors.centerIn: parent
            kind: "tiny"
            font.bold: true
            text: look.menu.hoveredEntry ? look.menu.hoveredEntry.label : ""
        }
    }

    // the ring
    Repeater {
        model: look.menu.slots
        Item {
            id: slot
            required property string modelData
            required property int index
            readonly property var e: DeskMenu.entry(modelData)
            readonly property real a: look.angleOf(index)
            readonly property bool sel: look.menu.current === index
            readonly property bool open: look.menu.fly === modelData
            // a little later for each slot: they fly out one after another
            readonly property real out: Math.max(0, Math.min(1, look.menu.reveal * 1.25 - index * 0.025))
            width: look.slotSize
            height: look.slotSize + look.labelRoom
            x: look.menu.cx + Math.cos(a) * look.r1 * out - width / 2
            y: look.menu.cy + Math.sin(a) * look.r1 * out - look.slotSize / 2
            opacity: out
            PxBox {
                id: tile
                width: look.slotSize
                height: look.slotSize
                scale: slot.sel || slot.open ? 1.14 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.ms(90)
                    }
                }
                sunken: slotMouse.pressed
                color: slot.sel || slot.open ? Theme.mix(Theme.face, Theme.accent, 0.4) : Qt.alpha(Theme.menuSurface, Math.max(0.88, Theme.panelAlpha))
                shadow: Config.appearance.shadows
                PxIcon {
                    anchors.centerIn: parent
                    name: slot.e ? slot.e.icon : "heart"
                    pixel: Math.max(1, Math.round(Theme.u * look.k))
                }
                // a flyout: a notch pointing outwards
                PxText {
                    visible: !!(slot.e && slot.e.flyout)
                    x: parent.width / 2 + Math.cos(slot.a) * (parent.width / 2 - Theme.u * 3) - width / 2
                    y: parent.height / 2 + Math.sin(slot.a) * (parent.height / 2 - Theme.u * 3) - height / 2
                    rotation: slot.a * 180 / Math.PI
                    kind: "tiny"
                    color: Theme.accent
                    text: "▸"
                }
            }
            PxText {
                visible: look.menu.labels
                anchors.horizontalCenter: tile.horizontalCenter
                anchors.top: tile.bottom
                anchors.topMargin: Theme.u
                width: Math.max(look.slotSize * 1.6, implicitWidth)
                horizontalAlignment: Text.AlignHCenter
                kind: "tiny"
                font.bold: slot.sel
                color: Theme.text
                style: Text.Outline
                styleColor: Qt.alpha(Theme.menuSurface, 0.9)
                text: slot.e ? (slot.e.short || slot.e.label) : ""
            }
            MouseArea {
                id: slotMouse
                width: look.slotSize
                height: look.slotSize
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: look.menu.hoverEntry(slot.index)
                onClicked: look.menu.activate(slot.index)
            }
        }
    }

    FlyColumn {
        menu: look.menu
        radius: look.r2
        reach: look.reach + Theme.u * 4
        angle: look.angleOf(look.menu.flyIndex)
    }
}
