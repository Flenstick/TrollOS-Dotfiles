import QtQuick
import QtQuick.Shapes
import qs.config

// TrollOS: Android's wavy progress (Material 3's "squiggly" seek bar): the played part a
// running sine wave, the rest a flat track, a short upright handle between them. While
// `playing` the wave rolls; paused, it settles flat (the amplitude eases to 0).
//   progress 0..1, color (the played part), track (the rest), handle (true: the upright bar)
Item {
    id: root

    property real progress: 0
    property bool playing: false
    property bool wavy: true
    property color color: Theme.accent
    property color track: Qt.alpha(Theme.text, 0.25)
    property bool handle: true
    property real stroke: Math.max(2, height / 7)
    property real wavelength: Math.max(16, height * 1.6)
    property real amplitude: height * 0.18

    // the wave's height now: grows while playing, settles when paused
    property real amp: playing && wavy ? amplitude : 0
    Behavior on amp {
        NumberAnimation {
            duration: Motion.ms(420)
            easing.type: Easing.InOutQuad
        }
    }
    property real phase: 0
    NumberAnimation on phase {
        running: root.playing && root.wavy && root.visible && !Motion.still
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }

    readonly property real cx: Math.max(0, Math.min(width, width * Math.max(0, Math.min(1, progress))))
    readonly property real gap: handle ? stroke * 2.2 : 0
    readonly property real mid: height / 2
    // the played part as points (one every 2 px)
    readonly property var wave: {
        const pts = [];
        const end = Math.max(0, cx - gap);
        const k = Math.PI * 2 / wavelength;
        for (let x = 0; x <= end; x += 2)
            pts.push(Qt.point(x, mid + Math.sin(x * k - phase) * amp));
        if (pts.length === 0 || pts[pts.length - 1].x < end)
            pts.push(Qt.point(end, mid + Math.sin(end * k - phase) * amp));
        return pts;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root.wave
            }
        }
        ShapePath {
            strokeColor: root.track
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: Math.min(root.width, root.cx + root.gap)
            startY: root.mid
            PathLine {
                x: Math.max(root.cx + root.gap, root.width - root.stroke / 2)
                y: root.mid
            }
        }
    }
    Rectangle {
        visible: root.handle
        x: root.cx - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.stroke * 1.4
        height: root.height * 0.85
        radius: width / 2
        color: root.color
    }
}
