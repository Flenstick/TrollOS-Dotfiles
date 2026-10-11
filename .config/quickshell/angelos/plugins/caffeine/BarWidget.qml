import QtQuick
import Quickshell.Wayland
import qs.config
import qs.widgets
import "."

// Cup on the bar: click toggles. Steam = awake.
// Включение: сверху льётся струя кофе, чашка наполняется по пикселю, на верху пенка,
// чашка подпрыгивает (сжатие → прыжок → приземление), поднимается пар.
// Выключение: пар тает, кофе выпивается сверху вниз, чашка устало приседает.
// Пока включено, пар покачивается.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    // TrollOS: the «Material You» skin — a coffee symbol, filled while awake
    readonly property bool md: Theme.settingsSkinFor(root) === "material"
    implicitWidth: md ? Theme.mdPx(36) : cup.implicitWidth + Theme.u * 4
    implicitHeight: Theme.u * 13

    // niri pauses idle timers (swayidle, auto-lock, screen off) while this is on
    IdleInhibitor {
        window: root.barWindow
        enabled: CaffeineState.active
    }

    property real level: CaffeineState.active ? 5 : 0   // 0..5 строк: 4 кофе + пенка
    property real steam: CaffeineState.active ? 3 : 0   // 0..3 строки пара
    property real pour: 0                                // 0..1 струя видна
    property real streamTop: 0                           // 0..1 хвост струи упал в чашку
    property real hop: 0                                 // прыжок, в арт-пикселях вверх
    property real squash: 1
    property int wig: 0
    readonly property bool animating: onAnim.running || offAnim.running

    // пар покачивается, пока кофеин включён
    Timer {
        interval: 520
        repeat: true
        running: CaffeineState.active && !root.animating
        onTriggered: root.wig = 1 - root.wig
    }

    readonly property var bitmap: {
        const L = Math.round(level), S = Math.floor(steam);
        const steamRows = wig ? [".w..w......", "..w..w.....", ".w..w......"] : ["..w..w.....", ".w..w......", "..w..w....."];
        const rows = steamRows.map((r, i) => i >= 3 - S ? r : "...........");
        const full = r => 8 - r < L;
        rows.push("#########..");
        rows.push("#" + (full(4) ? "yyyyyyy" : "fffffff") + "###");
        rows.push("#" + (full(5) ? "ooooooo" : "fffffff") + "#.#");
        rows.push("#" + (full(6) ? "ooooooo" : "fffffff") + "#.#");
        rows.push("#" + (full(7) ? "ooooooo" : "fffffff") + "###");
        rows.push(".#" + (full(8) ? "ooooo" : "fffff") + "#...");
        rows.push("..#####....");
        return rows;
    }

    Connections {
        target: CaffeineState
        function onToggled(on) {
            onAnim.stop();
            offAnim.stop();
            (on ? onAnim : offAnim).restart();
        }
    }

    MdSymbol {
        visible: root.md
        anchors.centerIn: parent
        name: "coffee"
        size: Theme.mdPx(22)
        fill: CaffeineState.active ? 1 : 0
        color: CaffeineState.active ? Theme.md.primary : Theme.md.onSurfaceVariant
    }
    PxIcon {
        id: cup
        visible: !root.md
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Math.round(root.hop) * Theme.u
        pixel: Theme.u
        opacity: CaffeineState.active || root.animating || mouse.containsMouse ? 1 : 0.55
        bitmap: Array.from(root.bitmap)
        transform: Scale {
            origin.x: cup.width / 2
            origin.y: cup.height
            yScale: root.squash
            xScale: 1 + (1 - root.squash) * 0.8
        }

        // струя кофе: сверху панели до поверхности
        Rectangle {
            readonly property real surfY: (9 - root.level) * Theme.u
            readonly property real headY: -cup.y + root.streamTop * (surfY + cup.y)
            visible: root.pour > 0 && surfY > headY
            x: 4 * Theme.u
            y: headY
            width: Theme.u
            height: surfY - headY
            color: cup.fill
            opacity: root.pour
        }
        // брызги у поверхности
        Repeater {
            model: 2
            Rectangle {
                required property int index
                readonly property real t: (root.level * 3) % 1
                visible: root.pour > 0.5 && root.streamTop < 0.5 && root.level < 4.8
                width: Theme.u
                height: Theme.u
                color: cup.light
                x: (index ? 5 + Math.round(t * 1.5) : 3 - Math.round(t * 1.5)) * Theme.u
                y: (8 - root.level - Math.round(Math.sin(t * Math.PI))) * Theme.u
            }
        }
    }

    SequentialAnimation {
        id: onAnim
        ScriptAction {
            script: {
                root.level = 0;
                root.steam = 0;
                root.streamTop = 0;
                root.hop = 0;
                root.squash = 1;
            }
        }
        NumberAnimation { target: root; property: "pour"; from: 0; to: 1; duration: 60 }
        NumberAnimation { target: root; property: "level"; from: 0; to: 5; duration: 650 }
        NumberAnimation { target: root; property: "streamTop"; from: 0; to: 1; duration: 110; easing.type: Easing.InQuad }
        PropertyAction { target: root; property: "pour"; value: 0 }
        // прыжок
        NumberAnimation { target: root; property: "squash"; to: 0.8; duration: 80; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: root; property: "squash"; to: 1.1; duration: 90 }
            NumberAnimation { target: root; property: "hop"; from: 0; to: 3; duration: 150; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "squash"; to: 1; duration: 120 }
            NumberAnimation { target: root; property: "hop"; to: 0; duration: 130; easing.type: Easing.InQuad }
        }
        NumberAnimation { target: root; property: "squash"; to: 0.88; duration: 60 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "squash"; to: 1; duration: 180; easing.type: Easing.OutBack; easing.overshoot: 3 }
            NumberAnimation { target: root; property: "steam"; from: 0; to: 3.99; duration: 420 }
        }
        PropertyAction { target: root; property: "steam"; value: 3 }
    }

    SequentialAnimation {
        id: offAnim
        ScriptAction {
            script: {
                root.pour = 0;
                root.hop = 0;
            }
        }
        NumberAnimation { target: root; property: "steam"; to: 0; duration: 260 }
        NumberAnimation { target: root; property: "level"; to: 0; duration: 420; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "squash"; to: 0.85; duration: 110; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "squash"; to: 1; duration: 220; easing.type: Easing.OutBack }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CaffeineState.toggle()
    }
}
