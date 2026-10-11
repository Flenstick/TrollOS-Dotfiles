import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."
import "Frames.js" as Frames

// Котик в бинтах: спит ниже порога «гуляет», дальше перебирает лапками, при большой
// загрузке — быстрее и вприпрыжку.
Item {
    id: root

    property var plugin
    property int pixel: Theme.u
    readonly property int walkAt: plugin ? plugin.get("walk", 15) : 15
    readonly property int runAt: Math.max(walkAt + 1, plugin ? plugin.get("run", 60) : 60)
    readonly property real cpu: Cpu.percent
    readonly property string pace: cpu < walkAt ? "idle" : cpu < runAt ? "walk" : "run"
    readonly property int frameMs: pace === "walk" ? 380 - (cpu - walkAt) / Math.max(1, runAt - walkAt) * 200 : 160 - (cpu - runAt) / Math.max(1, 100 - runAt) * 105
    property int frame: 0
    // гладят: мурчит (BarWidget), дрожит мелко, ушки подёргиваются
    property bool purring: false
    property int buzz: 0
    property real pet: 0           // 0..1 голову прижали ладонью
    function stroke() {
        petAnim.restart();
    }
    Timer {
        interval: 45
        running: root.purring
        repeat: true
        onTriggered: root.buzz = (root.buzz + 1) % 24
    }
    SequentialAnimation {
        id: petAnim
        NumberAnimation { target: root; property: "pet"; to: 1; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "pet"; to: 0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
    }
    // шаги — подпрыгивает (в беге выше)
    readonly property bool hop: pace !== "idle" && frame % 2 === 1

    implicitWidth: sprite.width
    implicitHeight: sprite.height + pixel * (pace === "run" ? 2 : 1)

    Timer {
        interval: Math.max(50, root.frameMs)
        running: root.pace !== "idle" && root.visible
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 4
    }
    Timer {
        // zzz мигает во сне
        interval: 700
        running: root.pace === "idle" && root.visible
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 2
    }

    PxIcon {
        id: sprite
        pixel: root.pixel
        bitmap: root.purring ? (root.buzz < 20 ? Frames.purr : Frames.purr2) : root.pace === "idle" ? Frames.sleep : Frames.run(root.frame)
        ink: Theme.mix(Theme.accent, Theme.edge, 0.3)
        body: "#100608"
        light: Theme.text
        bad: Theme.accent
        palette: ({
                "h": "#ff3040",
                "e": "#f5f0e6",
                "m": Theme.hex(Theme.text)
            })
        y: root.purring ? root.pixel * (root.pace === "run" ? 2 : 1) : root.hop ? 0 : root.pixel * (root.pace === "run" ? 2 : 1)
        transform: [
            Translate {
                x: root.purring ? (root.buzz % 2 ? 0.5 : -0.5) : 0
            },
            Scale {
                origin.x: sprite.width / 2
                origin.y: sprite.height
                yScale: 1 - 0.12 * root.pet
                xScale: 1 + 0.06 * root.pet
            }
        ]
    }
    PxText {
        visible: root.pace === "idle" && root.frame === 1 && !root.purring
        anchors.left: sprite.right
        anchors.leftMargin: -root.pixel
        anchors.top: sprite.top
        anchors.topMargin: -root.pixel * 3
        text: "z"
        kind: "tiny"
        color: Theme.accent2
    }
}
