pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Смена раскладки — красиво. Вместо плашки OSD (Config.osd.layout выключается, пока
// плагин включён; при выключении возвращается) над панелью по центру:
//   seal    печать: тёмно-красный диск в золотом кольце с перевёрнутой пентаграммой,
//           на нём готическая буква раскладки (Р / E); при смене печать переворачивается
//           как монета, на ребре буква меняется, вспышка и разлёт угольков
//   toggle  карточка «EN ⇄ RU»: пентаграмма-бегунок перекатывается к новой раскладке
// Стиль — plugin.get("style"), IPC `layoutfx test [стиль]`, `layoutfx style <стиль>`.
Item {
    id: root
    property var plugin
    readonly property string style: plugin ? plugin.get("style", "seal") : "seal"

    // буква и подпись раскладки — в её собственном алфавите
    function glyph(name) {
        const n = (name || "").toLowerCase();
        return n.startsWith("russian") ? "Р" : n.startsWith("ukrain") ? "У" : n.startsWith("english") ? "E" : (Niri.shortLayout(name) || "?").charAt(0).toUpperCase();
    }
    function label(name) {
        const n = (name || "").toLowerCase();
        return n.startsWith("russian") ? "русскій" : n.startsWith("ukrain") ? "українська" : n.startsWith("english") ? "english" : Niri.shortLayout(name).toLowerCase();
    }
    property string prevName: Niri.layoutName
    signal play(string from, string to, string style)

    Component.onCompleted: {
        if (plugin && plugin.get("savedOsdLayout", null) === null)
            plugin.set("savedOsdLayout", Config.osd.layout);
        Config.osd.layout = false;
    }
    Component.onDestruction: {
        if (plugin && plugin.get("savedOsdLayout", null) !== null)
            Config.osd.layout = plugin.get("savedOsdLayout", true);
    }

    Connections {
        target: Niri
        function onLayoutSwitched(name) {
            root.play(root.prevName, name, root.style);
            root.prevName = name;
        }
    }
    IpcHandler {
        target: "layoutfx"
        function test(style: string): void {
            const names = Niri.keyboardLayouts;
            const cur = Niri.layoutName, other = names.find(n => n !== cur) || cur;
            root.play(other, cur, style || root.style);
        }
        function style(s: string): string {
            if (root.plugin && ["seal", "toggle"].includes(s))
                root.plugin.set("style", s);
            return root.style;
        }
    }

    PanelWindow {
        id: win
        screen: Shell.focusedScreen
        property string from: ""
        property string to: ""
        property string kind: "seal"
        property bool shown: false
        visible: shown
        anchors.bottom: true
        margins.bottom: Theme.u * 6
        implicitWidth: 260
        implicitHeight: 170
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "angelos-layoutfx"
        WlrLayershell.layer: WlrLayer.Overlay

        Connections {
            target: root
            function onPlay(from, to, style) {
                win.from = from;
                win.to = to;
                win.kind = style;
                win.shown = true;
                if (style === "toggle")
                    toggleAnim.restart();
                else
                    sealAnim.restart();
            }
        }

        // ───────── печать ─────────
        Item {
            id: seal
            visible: win.kind === "seal"
            width: 92
            height: 92
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 46
            property real flip: 0          // 0..1: оборот монеты
            property real pop: 0           // 0..1: появление
            property real flash: 0
            property real fade: 1
            readonly property bool second: flip >= 0.5
            opacity: pop * fade

            // свечение: мягкий ореол из колец
            Repeater {
                model: 6
                Rectangle {
                    required property int index
                    anchors.centerIn: parent
                    width: seal.width * (1.02 + index * (0.08 + 0.05 * seal.flash))
                    height: width
                    radius: width / 2
                    color: Qt.alpha(Theme.accent, (0.07 + 0.10 * seal.flash) * (1 - index / 6))
                }
            }
            Item {
                id: coin
                anchors.fill: parent
                transform: Scale {
                    origin.x: coin.width / 2
                    xScale: Math.max(0.04, Math.abs(Math.cos(seal.flip * Math.PI)))
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.mix(Theme.desk, Theme.accent, 0.22)
                    border.width: 3
                    border.color: Theme.accent2
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 7
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent2, 0.6)
                }
                Canvas {
                    id: star
                    anchors.fill: parent
                    anchors.margins: 10
                    opacity: 0.35
                    onPaint: {
                        const c = getContext("2d");
                        c.reset();
                        const r = width / 2, cx = r, cy = r;
                        const p = [];
                        for (let i = 0; i < 5; i++) {
                            const a = (90 + 72 * i) * Math.PI / 180;
                            p.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]);
                        }
                        c.strokeStyle = Theme.hex(Theme.accent);
                        c.lineWidth = 2;
                        c.beginPath();
                        [0, 2, 4, 1, 3, 0].forEach((k, i) => i ? c.lineTo(p[k][0], p[k][1]) : c.moveTo(p[k][0], p[k][1]));
                        c.stroke();
                    }
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    text: root.glyph(seal.second ? win.to : win.from)
                    font.family: Theme.fontHell
                    font.pixelSize: 21 * 2
                    color: Theme.mix(Theme.text, Theme.accent2, 0.25)
                    style: Text.Outline
                    styleColor: Theme.edge
                    renderType: Text.NativeRendering
                }
            }
            // угольки
            Repeater {
                model: 10
                Rectangle {
                    required property int index
                    readonly property real a: index / 10 * Math.PI * 2 + 0.3
                    readonly property real d: 30 + seal.flash * 0 + (1 - seal.flash) * 34
                    visible: seal.second && seal.flash > 0.02
                    width: index % 3 === 0 ? 4 : 2
                    height: width
                    color: index % 2 ? Theme.accent : Theme.accent3
                    opacity: seal.flash
                    x: seal.width / 2 + Math.cos(a) * d - width / 2
                    y: seal.height / 2 + Math.sin(a) * d - height / 2
                }
            }
            PxText {
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label(win.to)
                font.family: Theme.fontHell
                font.pixelSize: 21
                color: Theme.text
                opacity: seal.second ? 1 : 0
            }

            SequentialAnimation {
                id: sealAnim
                PropertyAction { target: seal; property: "flip"; value: 0 }
                PropertyAction { target: seal; property: "fade"; value: 1 }
                PropertyAction { target: seal; property: "flash"; value: 0 }
                ParallelAnimation {
                    NumberAnimation { target: seal; property: "pop"; from: 0; to: 1; duration: 140 }
                    NumberAnimation { target: seal; property: "scale"; from: 0.7; to: 1; duration: 160; easing.type: Easing.OutBack }
                }
                NumberAnimation { target: seal; property: "flip"; from: 0; to: 1; duration: 380; easing.type: Easing.InOutCubic }
                ParallelAnimation {
                    NumberAnimation { target: seal; property: "flash"; from: 1; to: 0; duration: 520; easing.type: Easing.OutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: seal; property: "scale"; to: 1.08; duration: 90 }
                        NumberAnimation { target: seal; property: "scale"; to: 1.0; duration: 160 }
                    }
                }
                PauseAnimation { duration: 450 }
                NumberAnimation { target: seal; property: "fade"; to: 0; duration: 260 }
                PropertyAction { target: win; property: "shown"; value: false }
                PropertyAction { target: seal; property: "pop"; value: 0 }
            }
        }

        // ───────── переключатель ─────────
        Item {
            id: tog
            visible: win.kind === "toggle"
            width: 108
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            readonly property var names: Niri.keyboardLayouts.slice(0, 2)
            readonly property int toIdx: Math.max(0, names.indexOf(win.to))
            property real pos: 0           // 0..1 — где бегунок
            property real fade: 0
            opacity: fade

            PxBox {
                anchors.fill: parent
                color: Theme.panel
            }
            Rectangle {   // подсветка выбранной стороны
                x: 4 + tog.pos * (tog.width / 2 - 4)
                y: 4
                width: tog.width / 2 - 4
                height: tog.height - 8
                color: Qt.alpha(Theme.accent, 0.22)
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.6)
            }
            Repeater {
                model: tog.names
                PxText {
                    required property var modelData
                    required property int index
                    x: (index === 0 ? 0 : tog.width / 2) + 23
                    anchors.verticalCenter: parent.verticalCenter
                    text: Niri.shortLayout(modelData).toUpperCase()
                    font.bold: true
                    color: Math.round(tog.pos) === index ? Theme.text : Theme.textDim
                }
            }
            Canvas {   // пентаграмма-бегунок катится
                id: knob
                width: 15
                height: 15
                x: 7 + tog.pos * (tog.width / 2)
                anchors.verticalCenter: parent.verticalCenter
                rotation: -tog.pos * 216
                onPaint: {
                    const c = getContext("2d");
                    c.reset();
                    const r = width / 2 - 1.5, cx = width / 2, cy = height / 2;
                    c.strokeStyle = Theme.hex(Theme.accent);
                    c.lineWidth = 1.2;
                    c.beginPath();
                    c.arc(cx, cy, r, 0, Math.PI * 2);
                    c.stroke();
                    const p = [];
                    for (let i = 0; i < 5; i++) {
                        const a = (90 + 72 * i) * Math.PI / 180;
                        p.push([cx + (r - 1) * Math.cos(a), cy + (r - 1) * Math.sin(a)]);
                    }
                    c.beginPath();
                    [0, 2, 4, 1, 3, 0].forEach((k, i) => i ? c.lineTo(p[k][0], p[k][1]) : c.moveTo(p[k][0], p[k][1]));
                    c.stroke();
                }
            }
            SequentialAnimation {
                id: toggleAnim
                PropertyAction { target: tog; property: "pos"; value: 1 - tog.toIdx }
                NumberAnimation { target: tog; property: "fade"; from: 0; to: 1; duration: 120 }
                NumberAnimation { target: tog; property: "pos"; to: tog.toIdx; duration: 340; easing.type: Easing.OutBack }
                PauseAnimation { duration: 600 }
                NumberAnimation { target: tog; property: "fade"; to: 0; duration: 220 }
                PropertyAction { target: win; property: "shown"; value: false }
            }
        }
    }
}
