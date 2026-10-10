pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The middle of a circle's menu look: hell's horned logo (a click closes the menu) and the
// hovered entry's full name above it. The look sets its shape and colours.
Item {
    id: hub

    required property var menu              // RadialMenu
    property real size: Math.round(Theme.u * 24 * menu.k)
    property real corner: size / 2          // round by default
    property real tilt: 0
    property color color: Theme.hellPlate
    property color hover: Theme.hellFaceAlt
    property color rim: Theme.hellRim
    property bool showName: true
    property real nameGap: Theme.u * 3
    x: menu.cx - size / 2
    y: menu.cy - size / 2
    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: hub.corner
        rotation: hub.tilt
        scale: hub.menu.reveal
        color: hubMouse.containsMouse ? hub.hover : hub.color
        border.width: Math.max(1, Theme.u)
        border.color: hub.rim
    }
    AngelLogo {
        anchors.centerIn: parent
        scale: hub.menu.reveal
        emblemOnly: true
        hell: true
        pixel: Math.max(1, Math.round(Theme.u * hub.menu.k * 0.75))
    }
    MouseArea {
        id: hubMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            hub.menu.current = -1;
            hub.menu.fly = "";
        }
        onClicked: hub.menu.close()
    }
    // the hovered entry's full name
    Rectangle {
        visible: hub.showName && !!hub.menu.hoveredEntry && hub.menu.reveal > 0.6
        x: (hub.width - width) / 2
        y: -height - hub.nameGap
        width: hoverName.implicitWidth + Theme.u * 8
        height: hoverName.implicitHeight + Theme.u * 4
        color: Theme.hellPlate
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.hellRim
        PxText {
            id: hoverName
            anchors.centerIn: parent
            kind: "tiny"
            font.bold: true
            color: Theme.hellText
            text: hub.menu.hoveredEntry ? hub.menu.hoveredEntry.label : ""
        }
    }
}
