import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool checked: false
    property bool checkable: false
    property bool accent: false
    property bool danger: false
    property bool flat: false
    property bool compact: false
    property int iconPixel: Theme.u
    property bool middleButton: false      // also report middle clicks (task buttons close windows with them)
    property string kind: "body"
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    readonly property bool down: mouse.pressed || checked
    // Windows 11 Settings skin: Fluent standard / accent button
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow
    readonly property string fluentIcon: fluent && icon ? WinStyle.fluentIcon(icon) : ""
    signal clicked
    signal rightClicked
    signal middleClicked

    implicitWidth: fluent ? Math.max(32, frow.implicitWidth + (text !== "" ? 24 : 16)) : row.implicitWidth + (compact ? Theme.u * 6 : Theme.pad * 2 + Theme.u * 2)
    implicitHeight: fluent ? 32 : Math.max(row.implicitHeight + Theme.u * (compact ? 5 : 8), Theme.u * (compact ? 11 : 15))
    x: fluent && parent && parent.objectName === "settingSlot" ? parent.width - width : 0
    opacity: enabled ? 1 : 0.45

    Rectangle {
        visible: root.fluent && (!root.flat || mouse.containsMouse || root.checked)
        anchors.fill: parent
        radius: 4
        readonly property bool acc: root.accent || root.checked
        color: acc ? (mouse.pressed ? Qt.alpha(WinStyle.accent, 0.8) : mouse.containsMouse ? WinStyle.accentHover : WinStyle.accent) : root.danger && mouse.containsMouse ? "#c42b1c" : root.flat ? (mouse.pressed ? WinStyle.subtlePress : WinStyle.subtleHover) : mouse.pressed ? WinStyle.subtlePress : mouse.containsMouse ? WinStyle.controlHover : WinStyle.control
        border.width: root.flat ? 0 : 1
        border.color: acc ? Qt.rgba(0, 0, 0, 0.1) : WinStyle.controlLine
        Rectangle {
            // Fluent buttons have a slightly darker bottom edge
            visible: !root.flat && !parent.acc
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 8
            height: 1
            color: WinStyle.controlBottom
        }
    }
    Row {
        id: frow
        visible: root.fluent
        anchors.centerIn: parent
        spacing: 8
        Image {
            visible: root.fluentIcon !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            sourceSize: Qt.size(32, 32)
            source: root.fluentIcon ? Qt.resolvedUrl("../modules/bar/win/icons/" + ((root.accent || root.checked) ? (WinStyle.accentLight ? "l/" : "d/") : WinStyle.dark ? "d/" : "l/") + root.fluentIcon + ".svg") : ""
        }
        Text {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: (root.accent || root.checked) ? WinStyle.onAccent : root.danger && mouse.containsMouse ? "#ffffff" : WinStyle.text
            font.family: WinStyle.font
            font.pixelSize: 14
            renderType: Text.NativeRendering
        }
    }

    PxBox {
        anchors.fill: parent
        visible: !root.fluent && (!root.flat || mouse.containsMouse || root.checked)
        sunken: root.down
        color: root.accent ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : root.danger && mouse.containsMouse ? Theme.danger : root.checked ? Theme.mix(Theme.face, Theme.accent, Theme.dark ? 0.4 : 0.3) : mouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : Theme.face
    }

    Row {
        id: row
        visible: !root.fluent
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.down ? Theme.u : 0
        anchors.verticalCenterOffset: root.down ? Theme.u : 0
        spacing: Theme.u * 3

        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            pixel: root.iconPixel
            anchors.verticalCenter: parent.verticalCenter
            ink: root.accent ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
        }
        PxText {
            visible: root.text !== ""
            text: root.text
            kind: root.kind
            anchors.verticalCenter: parent.verticalCenter
            color: root.accent ? Theme.selectText : root.danger && mouse.containsMouse ? "#ffffff" : Theme.text
            font.bold: root.checked
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | (root.middleButton ? Qt.MiddleButton : 0)
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
            if (e.button === Qt.MiddleButton) {
                root.middleClicked();
                return;
            }
            if (root.checkable)
                root.checked = !root.checked;
            root.clicked();
        }
    }
}
