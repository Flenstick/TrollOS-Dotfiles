import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

// Котик в бинтах на панели (копия BarWidget встроенного плагина «Котик», свой спрайт).
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow
    readonly property bool showPercent: plugin ? plugin.get("showPercent", false) : false
    // the hell bar draws the Cerberus as he is (his colours are made for the dark plates)
    // instead of tinting him; the popup open is the state the bar shows
    property bool hellBar: false
    readonly property bool barOpen: popup.visible

    Component.onCompleted: if (plugin)
        Cpu.intervalMs = plugin.get("poll", 2) * 1000
    readonly property bool mac: Skin.mac
    implicitWidth: row.implicitWidth + (mac ? Skin.px(4) : Theme.u * 4)
    implicitHeight: mac ? Skin.px(18) : Theme.u * 13

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Skin.px(4)
        CatSprite {
            id: cat
            anchors.verticalCenter: parent.verticalCenter
            plugin: root.plugin
            purring: root.purring
            // the Mac cat is 8 × this tall: 16 pt at size ×1, like the menu bar's icons
            pixel: root.mac ? Math.max(1, GoldenGate.px(2) * (root.plugin ? root.plugin.get("size", 1) : 1)) : Math.max(1, Math.round(Theme.u * (root.plugin ? root.plugin.get("size", 1) : 1)))
        }
        PxText {
            visible: root.showPercent
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Cpu.percent) + "%"
            kind: "tiny"
            color: root.mac ? Skin.ink(root.screenName) : root.hellBar ? Theme.hellText : Theme.text
        }
    }
    // Погладь: зажми на котике и води по голове — он мурчит (звук), жмурится, краснеет,
    // дрожит, а над панелью всплывают милые сатанинские символы. Просто клик — окошко.
    property bool purring: false
    property real rub: 0            // пройдено ладонью с последнего символа
    property real lastX: 0
    property real lastY: 0
    property bool stroked: false
    readonly property string purrFile: Qt.resolvedUrl("purr.wav").toString().replace("file://", "")

    Timer {
        id: purrLeft            // ещё мурчит немного после того, как перестали гладить
        interval: 1400
        onTriggered: if (!pet.pressed)
            root.purring = false
    }
    Process {
        id: purrSound
        running: root.purring
        command: ["pw-play", "--volume", "0.55", root.purrFile]
        // по кругу, пока мурчит
        onExited: if (root.purring)
            Qt.callLater(() => purrSound.running = root.purring)
    }

    MouseArea {
        id: pet
        anchors.fill: parent
        cursorShape: root.stroked ? Qt.OpenHandCursor : Qt.PointingHandCursor
        preventStealing: true
        onPressed: m => {
            root.stroked = false;
            root.rub = 0;
            root.lastX = m.x;
            root.lastY = m.y;
        }
        onPositionChanged: m => {
            if (!pressed)
                return;
            root.rub += Math.hypot(m.x - root.lastX, m.y - root.lastY);
            root.lastX = m.x;
            root.lastY = m.y;
            if (!root.stroked && root.rub < Theme.u * 5)
                return;
            if (!root.stroked) {
                root.stroked = true;
                root.purring = true;
            }
            purrLeft.restart();
            if (root.rub >= Theme.u * 9) {
                root.rub = 0;
                cat.stroke();
                fx.spawn();
            }
        }
        onReleased: purrLeft.restart()
        onClicked: {
            if (!root.stroked)
                popup.toggle();
        }
    }

    // милые символы над котиком
    PanelWindow {
        id: fx
        property int alive: 0
        property int next: 0
        property real catX: 0
        function spawn() {
            const p = root.mapToItem(null, root.width / 2, 0);
            catX = p.x;
            next = (next + 1) % sparks.count;
            sparks.itemAt(next).go();
        }
        screen: root.barWindow ? root.barWindow.screen : null
        visible: alive > 0
        anchors.bottom: true
        anchors.left: true
        margins.left: Math.max(0, catX - width / 2)
        margins.bottom: root.barWindow ? root.barWindow.height - Theme.u * 2 : 40
        implicitWidth: 180
        implicitHeight: 150
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "angelos-cat-purr"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        readonly property var shapes: [
            // перевёрнутая пентаграмма
            ["..#...#..", "..##.##..", "...###...", "..##.##..", ".#.#.#.#.", "#########", "....#....", "....#...."],
            // сердечко с рожками
            ["h.......h", "hh.....hh", ".hhh.hhh.", "hhhhhhhhh", "hhhhwhhhh", ".hhhhhhh.", "..hhhhh..", "...hhh...", "....h...."],
            // перевёрнутый крестик
            ["..h..", "..h..", "..h..", "..h..", "hhhhh", "..h..", "..h.."],
            // маленькое сердечко
            [".hh.hh.", "hhhhhhh", "hwhhhhh", ".hhhhh.", "..hhh..", "...h..."],
            // чертёнок: рожки и улыбка
            ["#.....#", "##...##", ".#####.", "#h#h#h#", "#hhhhh#", "#h#h#h#", ".#####."]
        ]

        Repeater {
            id: sparks
            model: 10
            Item {
                id: sp
                required property int index
                property real t: 0
                property int shape: 0
                property real side: 0
                property real spin: 0
                property bool word: false
                visible: t > 0 && t < 1
                x: fx.width / 2 + side * (10 + t * 26) + Math.sin(t * 7 + index) * 6 - width / 2
                y: fx.height - 14 - t * (fx.height - 30) - height / 2
                width: word ? mrr.width : ic.width
                height: word ? mrr.height : ic.height
                opacity: t < 0.15 ? t / 0.15 : 1 - Math.max(0, (t - 0.6) / 0.4)
                scale: t < 0.18 ? 0.3 + t / 0.18 * 0.9 : 1.2 - Math.min(0.2, (t - 0.18))
                rotation: word ? 0 : spin * t
                function go() {
                    word = Math.random() < 0.18;
                    shape = Math.floor(Math.random() * fx.shapes.length);
                    side = Math.random() * 2 - 1;
                    spin = (Math.random() * 2 - 1) * 40;
                    fly.restart();
                }
                PxIcon {
                    id: ic
                    visible: !sp.word
                    pixel: Theme.u
                    bitmap: Array.from(fx.shapes[sp.shape])
                    ink: sp.shape === 0 ? Theme.accent2 : "#3a0a14"
                    light: "#ffd6e2"
                    palette: ({
                            "h": "#ff4d7d"
                        })
                }
                PxText {
                    id: mrr
                    visible: sp.word
                    text: ["мрр", "мурр♡", "мрр~"][sp.index % 3]
                    kind: "tiny"
                    color: "#ff8fb0"
                }
                SequentialAnimation {
                    id: fly
                    ScriptAction {
                        script: fx.alive++
                    }
                    NumberAnimation {
                        target: sp
                        property: "t"
                        from: 0.001
                        to: 1
                        duration: 1500
                        easing.type: Easing.OutQuad
                    }
                    ScriptAction {
                        script: fx.alive = Math.max(0, fx.alive - 1)
                    }
                }
            }
        }
    }

    BarPopup {
        id: popup
        panelId: "cat"
        anchorItem: root
        above: BarLayout.bottom
        title: Skin.title(I18n.t("котик", "cat"))
        icon: "heart"
        contentWidth: Skin.px(240)
        contentHeight: Skin.px(140)

        Column {
            anchors.centerIn: parent
            spacing: Skin.px(8)
            CatSprite {
                anchors.horizontalCenter: parent.horizontalCenter
                plugin: root.plugin
                pixel: root.mac ? GoldenGate.px(6) : Theme.u * 4
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                kind: "title"
                text: "CPU " + Math.round(Cpu.percent) + "%"
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                dim: true
                readonly property int pace: Cpu.percent < (root.plugin ? root.plugin.get("walk", 15) : 15) ? 0 : Cpu.percent < (root.plugin ? root.plugin.get("run", 60) : 60) ? 1 : 2
                text: [I18n.t("спит… zzz", "Sleeping… zzz"), I18n.t("гуляет, хромая ♡", "Limping along ♡"), I18n.t("СКАЧЕТ!!", "HOPPING!!")][pace]
            }
        }
    }
}
