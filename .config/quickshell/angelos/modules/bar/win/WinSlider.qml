import QtQuick
import qs.services

// Fluent slider: thin track, accent fill, round thumb whose inner dot grows on hover.
Item {
    id: root
    property real value: 0          // 0..1
    signal moved(real value)
    implicitHeight: 32
    implicitWidth: 200

    readonly property real shown: ma.pressed ? drag : value
    property real drag: 0

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: 10
        width: parent.width - 20
        height: 4
        radius: 2
        color: WinStyle.dark ? Qt.rgba(1, 1, 1, 0.54) : Qt.rgba(0, 0, 0, 0.45)
        Rectangle {
            width: Math.max(0, Math.min(1, root.shown)) * parent.width
            height: parent.height
            radius: 2
            color: WinStyle.accent
        }
    }
    Rectangle {
        id: thumb
        width: 20
        height: 20
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: track.x + Math.max(0, Math.min(1, root.shown)) * track.width - 10
        color: WinStyle.dark ? "#454545" : "#ffffff"
        border.width: 1
        border.color: WinStyle.controlLine
        Rectangle {
            anchors.centerIn: parent
            property real d: ma.pressed ? 10 : ma.containsMouse ? 14 : 12
            width: d
            height: d
            radius: d / 2
            color: WinStyle.accent
            Behavior on d {
                NumberAnimation {
                    duration: WinStyle.fast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        function at(x) {
            return Math.max(0, Math.min(1, (x - track.x) / track.width));
        }
        onPressed: m => {
            root.drag = at(m.x);
            root.moved(root.drag);
        }
        onPositionChanged: m => {
            if (pressed) {
                root.drag = at(m.x);
                root.moved(root.drag);
            }
        }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.02 : -0.02))))
    }
}
