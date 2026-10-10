import QtQuick
import qs.config
import qs.services

// Win98-style bevelled box. raised by default, `sunken` for inputs/pressed.
Item {
    id: root

    property color color: Theme.face
    property int bevel: Theme.u
    property bool sunken: false
    property bool outline: true
    property bool flat: false
    property bool shadow: false
    property int shadowSize: Theme.u * 2
    property color hiColor: Theme.hi
    property color loColor: Theme.lo
    property color edgeColor: Theme.edge
    // Windows 11 Settings skin: a rounded Fluent surface instead of the bevel
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow
    property int fluentRadius: 4
    readonly property int ob: fluent ? 0 : outline ? bevel : 0
    readonly property int inset: fluent ? 0 : ob + (flat ? 0 : bevel)
    default property alias content: inner.data

    // hard pixel shadow (right + bottom strips so translucent boxes stay clean)
    Rectangle {
        visible: root.fluent
        anchors.fill: parent
        radius: root.fluentRadius
        color: root.sunken ? WinStyle.field : Qt.colorEqual(root.color, Theme.accent) ? WinStyle.accent : Qt.colorEqual(root.color, Theme.sunken) ? WinStyle.field : WinStyle.control
        border.width: root.outline ? 1 : 0
        border.color: WinStyle.controlLine
    }
    Rectangle {
        visible: root.shadow && !root.fluent
        x: root.width
        y: root.shadowSize
        width: root.shadowSize
        height: root.height
        color: Qt.alpha(Theme.shadow, Theme.dark ? 0.55 : 0.35)
    }
    Rectangle {
        visible: root.shadow && !root.fluent
        x: root.shadowSize
        y: root.height
        width: root.width
        height: root.shadowSize
        color: Qt.alpha(Theme.shadow, Theme.dark ? 0.55 : 0.35)
    }

    Rectangle {
        visible: !root.fluent
        anchors.fill: parent
        color: root.color
        border.width: root.ob
        border.color: root.edgeColor
    }
    Rectangle {
        visible: !root.flat && !root.fluent
        x: root.ob
        y: root.ob
        width: root.width - 2 * root.ob
        height: root.bevel
        color: root.sunken ? root.loColor : root.hiColor
    }
    Rectangle {
        visible: !root.flat && !root.fluent
        x: root.ob
        y: root.ob
        width: root.bevel
        height: root.height - 2 * root.ob
        color: root.sunken ? root.loColor : root.hiColor
    }
    Rectangle {
        visible: !root.flat && !root.fluent
        x: root.ob + root.bevel
        y: root.height - root.ob - root.bevel
        width: root.width - 2 * root.ob - root.bevel
        height: root.bevel
        color: root.sunken ? root.hiColor : root.loColor
    }
    Rectangle {
        visible: !root.flat && !root.fluent
        x: root.width - root.ob - root.bevel
        y: root.ob + root.bevel
        width: root.bevel
        height: root.height - 2 * root.ob - root.bevel
        color: root.sunken ? root.hiColor : root.loColor
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.inset
    }
}
