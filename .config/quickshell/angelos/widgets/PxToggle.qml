import QtQuick
import qs.config
import qs.services

// Pixel switch with a heart knob. In the Windows 11 Settings skin: a Fluent
// toggle switch with "Откл./Вкл." on its left, sitting at the right of the row.
Item {
    id: root

    property bool checked: false
    property string text: ""
    signal toggled(bool checked)
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    implicitWidth: fluent ? fstate.implicitWidth + 12 + 40 : track.width + (label.visible ? label.implicitWidth + Theme.u * 5 : 0)
    implicitHeight: fluent ? 32 : Math.max(track.height, label.implicitHeight)
    x: fluent && parent && parent.objectName === "settingSlot" ? parent.width - width : 0
    opacity: enabled ? 1 : 0.45

    PxBox {
        id: track
        visible: !root.fluent
        width: Theme.u * 26
        height: Theme.u * 13
        anchors.verticalCenter: parent.verticalCenter
        sunken: true
        color: root.checked ? Theme.mix(Theme.sunken, Theme.accent, 0.55) : Theme.sunken

        PxBox {
            id: knob
            width: parent.height
            height: width
            y: 0
            x: root.checked ? parent.width - width : 0
            color: root.checked ? Theme.accent : Theme.face
            Behavior on x {
                NumberAnimation {
                    duration: Theme.fast
                    easing.type: Easing.OutBack
                }
            }
            PxIcon {
                anchors.centerIn: parent
                name: "heartSmall"
                pixel: Math.max(1, Theme.u - 1)
                fill: root.checked ? "#ffffff" : Theme.lo
                ink: root.checked ? Theme.edge : Theme.textDim
            }
        }
    }

    PxText {
        id: label
        visible: !root.fluent && root.text !== ""
        text: root.text
        anchors.left: track.right
        anchors.leftMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
    }

    // ---- Fluent ----
    Text {
        id: fstate
        visible: root.fluent
        anchors.verticalCenter: parent.verticalCenter
        text: root.text !== "" ? root.text : root.checked ? I18n.t("Вкл.", "On") : I18n.t("Откл.", "Off")
        color: WinStyle.text
        font.family: WinStyle.font
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }
    Rectangle {
        id: fswitch
        visible: root.fluent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 20
        radius: 10
        color: root.checked ? (ma.containsMouse ? WinStyle.accentHover : WinStyle.accent) : ma.containsMouse ? WinStyle.subtleHover : "transparent"
        border.width: root.checked ? 0 : 1
        border.color: WinStyle.text2
        Behavior on color {
            ColorAnimation {
                duration: WinStyle.fast
            }
        }
        Rectangle {
            readonly property real d: ma.pressed ? 14 : ma.containsMouse ? 14 : 12
            width: ma.pressed ? 17 : d
            height: d
            radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 4 : 4
            color: root.checked ? WinStyle.onAccent : WinStyle.text2
            Behavior on x {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: WinStyle.fast
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
