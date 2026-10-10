import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property bool checked: false
    property string text: ""
    signal toggled(bool checked)
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    implicitWidth: box.width + (text !== "" ? label.implicitWidth + Theme.u * 4 : 0)
    implicitHeight: Math.max(box.height, label.implicitHeight)
    opacity: enabled ? 1 : 0.45

    Rectangle {
        visible: root.fluent
        anchors.fill: box
        radius: 4
        color: root.checked ? WinStyle.accent : WinStyle.field
        border.width: root.checked ? 0 : 1
        border.color: WinStyle.text2
        Text {
            anchors.centerIn: parent
            visible: root.checked
            text: "✓"
            color: WinStyle.onAccent
            font.pixelSize: 14
            font.bold: true
        }
    }
    PxBox {
        id: box
        opacity: root.fluent ? 0 : 1
        width: root.fluent ? 20 : Theme.u * 10
        height: width
        sunken: true
        color: Theme.sunken
        anchors.verticalCenter: parent.verticalCenter
        PxIcon {
            anchors.centerIn: parent
            visible: root.checked
            name: "check"
            pixel: Math.max(1, Theme.u - 1)
            ink: Theme.accent
        }
    }
    PxText {
        id: label
        text: root.text
        anchors.left: box.right
        anchors.leftMargin: Theme.u * 4
        anchors.verticalCenter: parent.verticalCenter
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
