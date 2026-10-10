pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import "../panel-shooter"

// «Друг в сети»: Equicord-плагин AngelosFriends зовёт `qs ipc call friends arrive '{json}'`,
// и внизу экрана справа налево пробегает пиксельный человечек: голова — аватарка
// друга (пикселизованная), над ним нимб и облачко с ником. Остров он перепрыгивает.
// С пистолетом из плагина «Тир на панели» (panel-shooter) по нему можно стрелять:
// тир спрашивает Gun.hitTest, и при попадании человечек падает и «выходит из сети».
// Если он сидит в войсе, попадание уходит в Discord (`shot <id>` в сокет AngelosFriends),
// и его кикает из голосового канала. Кто заходит в мой войс — тоже пробегает (это шлёт Equicord).
// ЛКМ по человечку — схватить его и унести в «Пыточную» (плагин torture-room; любимого там
// не пытают — у него своё меню с нежностями), ПКМ — открыть Discord.
Item {
    id: root

    property var plugin
    property var queue: []
    property var cur: null            // {id, name, avatar, status, voice, kickable}
    property bool dead: false         // застрелен из тира
    property bool headshot: false
    property real deadAt: 0
    property bool held: false         // унесён в пыточную
    property string note: ""          // подпись в облачке после пыточной
    // любимый человек: за его человечком тянется шлейф из красных сердечек
    readonly property string beloved: plugin ? plugin.get("beloved", "") : ""
    readonly property bool loved: !!cur && cur.id === beloved && !dead

    // цель для тира: (x, пикселей от низа экрана) -> null | {head, name}
    readonly property var target: (x, fromBottom) => root.hitTest(x, fromBottom)
    Component.onCompleted: Gun.register(target)

    function hitTest(x, fromBottom) {
        if (!cur || dead || !run.running)
            return null;
        const y = win.height - fromBottom;
        const pad = win.k;
        const top = runner.y;
        const bottom = runner.y + runner.height;
        if (x < runner.x - pad || x > runner.x + runner.width + pad || y < top - pad || y > bottom + pad)
            return null;
        const head = y < runner.y + headBox.y + headBox.height;
        run.stop();
        if (/^\d{15,21}$/.test(cur.id))
            discord("shot " + cur.id);
        headshot = head;
        dead = true;
        deadAt = Date.now();
        death.restart();
        return {
            "head": head,
            "name": cur.name
        };
    }

    // схватить бегущего и отдать пыточной (Gun.victim); вернётся через Gun.victimReleased
    function grab() {
        if (!cur || dead || held || !run.running || !Gun.chamber)
            return false;
        const sh = win.screen ? win.screen.height : win.height;
        if (!Gun.grab({
                "owner": "friend-runner",
                "kind": "friend",
                "id": cur.id,
                "name": cur.name,
                "avatar": cur.avatar || "",
                "beloved": cur.id === beloved,
                "dir": -1,
                "sx": runner.x + runner.width / 2,
                "sy": sh - (win.height - win.ground)
            }))
            return false;
        run.stop();
        held = true;
        return true;
    }
    Connections {
        target: Gun
        function onVictimReleased(v, info) {
            if (v.owner !== "friend-runner" || !root.held)
                return;
            root.held = false;
            root.note = v.beloved ? (root.cur ? root.cur.name : "") + " ❤" : info.broken ? "…" : (root.cur ? root.cur.name : "") + " сбежал!";
            runner.start(info.x);
        }
    }
    Component.onDestruction: {
        Gun.unregister(target);
        if (Gun.victim && Gun.victim.owner === "friend-runner")
            Gun.victim = null;
    }

    function enqueue(f) {
        if ((cur && cur.id === f.id) || queue.some(q => q.id === f.id))
            return;
        queue = queue.concat([f]);
        if (!cur)
            next.restart();
    }
    Timer {
        id: next
        interval: 500
        onTriggered: {
            if (!root.queue.length)
                return;
            root.cur = root.queue[0];
            root.queue = root.queue.slice(1);
            runner.start();
        }
    }
    function finished() {
        cur = null;
        held = false;
        note = "";
        dead = false;
        headshot = false;
        if (queue.length)
            next.restart();
    }

    // команды Equicord-плагину AngelosFriends: "shot <id>" — кикнуть из войса, "voice" — выпустить мой войс
    property var outbox: []
    // соединение держим открытым: если закрыть сразу после write, Quickshell теряет неотправленное
    function discord(cmd) {
        if (disc.connected) {
            disc.write(cmd + "\n");
            disc.flush();
            return;
        }
        outbox = outbox.concat([cmd]);
        disc.connected = true;
    }
    Socket {
        id: disc
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/angelos-friends.sock"
        onConnectedChanged: {
            if (!connected)
                return;
            for (const c of root.outbox)
                write(c + "\n");
            root.outbox = [];
            flush();
        }
        onError: {
            root.outbox = [];
            connected = false;
        }
    }

    IpcHandler {
        target: "friends"
        // payload: {"id", "name", "avatar", "status"}
        function arrive(payload: string): void {
            try {
                const f = JSON.parse(payload);
                if (f && f.name)
                    root.enqueue(f);
            } catch (e) {
                console.log("friend-runner: плохой payload", payload);
            }
        }
        // унести бегущего друга в пыточную
        function grab(): string {
            return root.grab() ? "grabbed" : "nobody to grab";
        }
        function voice(): void {
            root.discord("voice");
        }
        // дождь из сердечек на весь экран (AngelosLove: он поставил сердечко на моё сообщение)
        function rain(): void {
            root.raining = true;
            rainEnd.restart();
            Qt.callLater(() => {
                for (let i = 0; i < drops.count; i++)
                    drops.itemAt(i).fall();
            });
        }
        // он написал, что любит: payload {"name", "avatar", "text"}
        function love(payload: string): void {
            try {
                root.showLove(JSON.parse(payload));
            } catch (e) {
                console.log("friend-runner: плохой payload love", payload);
            }
        }
        function testLoveMessage(): void {
            root.showLove({
                "name": "Назар",
                "avatar": "",
                "text": "люблю тебя ❤"
            });
        }
        function testLove(): void {      // пробежать любимым (с сердечками)
            root.enqueue({
                "id": root.beloved,
                "name": "Любимый",
                "avatar": "",
                "status": "online"
            });
        }
        function test(): void {
            root.enqueue({
                "id": "test-" + Date.now(),
                "name": "Тестовый друг",
                "avatar": "",
                "status": "online"
            });
        }
    }

    // ── «он любит тебя»: несколько секунд на весь экран ──
    property var loveData: null
    function showLove(d) {
        loveData = d;
        loveAnim.restart();
    }
    SequentialAnimation {
        id: loveAnim
        ScriptAction {
            script: {
                loveWin.veil = 0;
                loveWin.pop = 0;
                loveWin.beat = 1;
                loveWin.fade = 1;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: loveWin; property: "veil"; to: 1; duration: 450; easing.type: Easing.OutQuad }
            NumberAnimation { target: loveWin; property: "pop"; to: 1; duration: 650; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        }
        ScriptAction { script: loveWin.burst() }
        SequentialAnimation {
            loops: 3
            NumberAnimation { target: loveWin; property: "beat"; to: 1.12; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: loveWin; property: "beat"; to: 1; duration: 180; easing.type: Easing.InQuad }
            NumberAnimation { target: loveWin; property: "beat"; to: 1.18; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: loveWin; property: "beat"; to: 1; duration: 500; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: loveWin.burst() }
        PauseAnimation { duration: 500 }
        NumberAnimation { target: loveWin; property: "fade"; to: 0; duration: 700; easing.type: Easing.InQuad }
        ScriptAction { script: root.loveData = null }
    }

    PanelWindow {
        id: loveWin
        readonly property real sw: screen ? screen.width : 1920
        readonly property real sh: screen ? screen.height : 1080
        readonly property int u: Theme.u
        property real veil: 0
        property real pop: 0
        property real beat: 1
        property real fade: 1
        property int burstN: 0
        function burst() {
            for (let i = 0; i < 14; i++) {
                burstN = (burstN + 1) % sparks.count;
                sparks.itemAt(burstN).fly(i / 14 * Math.PI * 2 + Math.random() * 0.3);
            }
        }

        screen: Shell.focusedScreen
        visible: !!root.loveData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "angelos-love"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            opacity: loveWin.fade

            Rectangle {
                anchors.fill: parent
                color: "#2a000b"
                opacity: loveWin.veil * 0.5
            }
            // розовая дымка по краям
            Rectangle {
                anchors.fill: parent
                opacity: loveWin.veil * 0.55
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: "#a0102a" }
                    GradientStop { position: 0.35; color: "#00000000" }
                    GradientStop { position: 0.65; color: "#00000000" }
                    GradientStop { position: 1; color: "#a0102a" }
                }
            }

            Item {
                id: centre
                x: loveWin.sw / 2
                y: loveWin.sh / 2 - loveWin.u * 30
                scale: loveWin.pop * loveWin.beat

                PxIcon {
                    id: big
                    anchors.centerIn: parent
                    name: "heart"
                    pixel: loveWin.u * 16
                    fill: "#e8173a"
                    ink: "#5a0610"
                    light: "#ffb3c4"
                }
                Rectangle {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -loveWin.u * 6
                    width: loveWin.u * 56
                    height: width
                    color: "#5a0610"
                    visible: ava.status === Image.Ready
                    Image {
                        id: ava
                        anchors.fill: parent
                        anchors.margins: loveWin.u * 4
                        source: root.loveData ? root.loveData.avatar || "" : ""
                        sourceSize: Qt.size(16, 16)
                        smooth: false
                    }
                }
            }

            Rectangle {
                anchors.centerIn: loveText
                width: loveText.width + loveWin.u * 24
                height: loveText.height + loveWin.u * 12
                color: "#e01a0508"
                border.color: "#e8173a"
                border.width: loveWin.u
                opacity: loveWin.pop
            }
            Column {
                id: loveText
                anchors.horizontalCenter: parent.horizontalCenter
                y: centre.y + big.height / 2 + loveWin.u * 20
                spacing: loveWin.u * 4
                opacity: loveWin.pop
                PxText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.loveData ? (root.loveData.name || "Он") + " любит тебя!" : ""
                    color: "#ffffff"
                    font.pixelSize: Theme.sizeTitle * 2.4
                    font.bold: true
                    style: Text.Outline
                    styleColor: "#a0102a"
                }
                PxText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, loveWin.sw * 0.6)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.loveData && root.loveData.text ? "«" + root.loveData.text + "»" : ""
                    color: "#ffd0da"
                    font.pixelSize: Theme.sizeTitle * 1.3
                    style: Text.Outline
                    styleColor: "#5a0610"
                }
            }

            // сердечки разлетаются из центра
            Repeater {
                id: sparks
                model: 28
                PxIcon {
                    id: sp
                    required property int index
                    name: "heart"
                    fill: ["#e8173a", "#ff3d64", "#ff7a90", "#ffb3c4"][index % 4]
                    ink: "#5a0610"
                    opacity: 0
                    property real ang: 0
                    property real dist: 0
                    x: loveWin.sw / 2 + Math.cos(ang) * dist - width / 2
                    y: centre.y + Math.sin(ang) * dist - height / 2
                    function fly(a) {
                        ang = a;
                        pixel = loveWin.u * (2 + Math.floor(Math.random() * 3));
                        flyAnim.restart();
                    }
                    ParallelAnimation {
                        id: flyAnim
                        NumberAnimation { target: sp; property: "dist"; from: loveWin.u * 40; to: loveWin.u * (150 + Math.random() * 120); duration: 1400; easing.type: Easing.OutCubic }
                        SequentialAnimation {
                            PropertyAction { target: sp; property: "opacity"; value: 1 }
                            PauseAnimation { duration: 800 }
                            NumberAnimation { target: sp; property: "opacity"; to: 0; duration: 600 }
                        }
                    }
                }
            }
        }
    }

    property bool raining: false
    Timer {
        id: rainEnd
        interval: 7500
        onTriggered: root.raining = false
    }

    PanelWindow {
        id: rainWin
        // размеры экрана, а не окна: окно только что стало видимым и ещё не знает своих
        readonly property real sw: screen ? screen.width : 1920
        readonly property real sh: screen ? screen.height : 1080
        screen: Shell.focusedScreen
        visible: root.raining
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "angelos-heart-rain"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Repeater {
            id: drops
            model: 90
            PxIcon {
                id: d
                required property int index
                readonly property var reds: ["#e8173a", "#ff3d64", "#c4101f", "#ff7a90", "#d4101f"]
                name: "heart"
                pixel: Theme.u
                ink: "#5a0610"
                opacity: 0
                property real drift: 0
                function fall() {
                    pixel = Theme.u * (1 + Math.floor(Math.random() * 3));
                    fill = reds[Math.floor(Math.random() * reds.length)];
                    x = Math.random() * rainWin.sw;
                    y = -height - Math.random() * 40;
                    drift = (Math.random() - 0.5) * 160;
                    pause.duration = Math.random() * 3000;
                    drop.duration = 2600 + Math.random() * 2200;
                    rain.restart();
                }
                SequentialAnimation {
                    id: rain
                    PauseAnimation {
                        id: pause
                    }
                    PropertyAction {
                        target: d
                        property: "opacity"
                        value: 0.95
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            id: drop
                            target: d
                            property: "y"
                            to: rainWin.sh + 20
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: d
                            property: "x"
                            to: d.x + d.drift
                            duration: drop.duration
                            easing.type: Easing.InOutSine
                        }
                        SequentialAnimation {
                            PauseAnimation {
                                duration: drop.duration * 0.7
                            }
                            NumberAnimation {
                                target: d
                                property: "opacity"
                                to: 0
                                duration: drop.duration * 0.3
                            }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: win

        readonly property int u: Theme.u
        readonly property int k: Math.max(2, Math.round(Theme.u * 1.5))   // пиксель человечка
        readonly property bool island: (Config.bar.screens || []).includes("dynamic-island")
        // где земля: у острова — по нижнему краю экрана, у обычной панели — на её крыше
        readonly property int ground: height - (island ? u * 2 : Config.bar.style === "taskbar" ? u * 20 : u * 2)
        readonly property real jumpHalf: u * 80
        readonly property real jumpHeight: u * 26

        screen: Shell.focusedScreen
        visible: !!root.cur && !root.held
        anchors {
            bottom: true
            left: true
            right: true
        }
        implicitHeight: u * 90
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        // с пистолетом в руке клики забирает тир, а не этот слой
        mask: Region {
            item: Gun.armed || root.held ? null : runner
        }
        WlrLayershell.namespace: "angelos-friends"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // пылинки из-под ног
        Repeater {
            id: dust
            model: 5
            Rectangle {
                id: puff
                required property int index
                width: win.k * 2
                height: win.k * 2
                color: Qt.alpha(Theme.textDim, 0.8)
                opacity: 0
                function kick(px, py) {
                    x = px;
                    y = py;
                    puffAnim.restart();
                }
                ParallelAnimation {
                    id: puffAnim
                    NumberAnimation {
                        target: puff
                        property: "opacity"
                        from: 0.8
                        to: 0
                        duration: 420
                    }
                    NumberAnimation {
                        target: puff
                        property: "y"
                        to: puff.y - win.u * 4
                        duration: 420
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: puff
                        property: "x"
                        to: puff.x + win.u * 6
                        duration: 420
                    }
                }
            }
        }

        // шлейф сердечек за любимым
        Repeater {
            id: hearts
            model: 16
            PxIcon {
                id: h
                required property int index
                name: "heart"
                pixel: win.u
                fill: "#e8173a"
                ink: "#5a0610"
                opacity: 0
                property real drift: 0
                function kick(px, py) {
                    x = px;
                    y = py;
                    drift = (Math.random() - 0.5) * win.u * 16;
                    pixel = Math.random() < 0.35 ? win.u * 2 : win.u;
                    heartAnim.restart();
                }
                ParallelAnimation {
                    id: heartAnim
                    NumberAnimation {
                        target: h
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 1100
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: h
                        property: "y"
                        to: h.y - win.u * 22
                        duration: 1100
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: h
                        property: "x"
                        to: h.x + win.u * 10 + h.drift
                        duration: 1100
                    }
                }
            }
        }

        // лужа под застреленным и душа, улетающая вверх
        Rectangle {
            readonly property real grow: root.dead ? Math.min(1, (ghostClock.now - root.deadAt - 200) / 1400) : 0
            visible: grow > 0 && runner.opacity > 0
            width: col.height * 1.1 * grow
            height: win.k
            x: runner.x + runner.width / 2 + col.height / 2 - width / 2
            y: win.ground - height
            color: "#8e0f16"
            opacity: runner.opacity
        }
        PxIcon {
            readonly property real t: (ghostClock.now - root.deadAt - 500) / 2200
            visible: root.dead && t > 0 && t < 1
            x: runner.x + runner.width / 2 + col.height / 2 - width / 2 + Math.sin(t * 9) * win.u * 2
            y: win.ground - win.k * 12 - height - t * win.u * 45
            name: "ghost"
            pixel: win.u * 2
            fill: "#ffffff"
            opacity: (1 - t) * 0.85
        }
        FrameAnimation {
            id: ghostClock
            property real now: 0
            running: root.dead
            onTriggered: now = Date.now()
        }

        Item {
            id: runner

            property real px: win.width
            property int frame: 0
            property int puffN: 0
            property int heartN: 0
            readonly property real center: px + width / 2
            readonly property real jt: (center - (win.width / 2 - win.jumpHalf)) / (2 * win.jumpHalf)
            readonly property bool jumping: !root.dead && win.island && jt > 0 && jt < 1
            property real fall: 0
            readonly property real lift: jumping ? 4 * win.jumpHeight * jt * (1 - jt) : 0

            // fromX — центр, откуда бежать (после пыточной): тогда бежит вдвое быстрее
            function start(fromX) {
                fall = 0;
                opacity = 1;
                const escape = fromX !== undefined;
                px = escape ? fromX - width / 2 : (win.screen ? win.screen.width : win.width) + win.u * 10;
                run.from = px;
                run.to = -width - bubble.width;
                run.duration = Math.max(300, Math.round((run.from - run.to) / (escape ? 0.64 : 0.32)));
                run.restart();
            }

            width: win.k * 12
            height: col.height
            x: Math.round(px)
            y: win.ground - height - Math.round(lift)

            NumberAnimation {
                id: run
                target: runner
                property: "px"
                onFinished: root.finished()
            }
            // застрелили: падает на спину, лежит, растворяется
            SequentialAnimation {
                id: death
                NumberAnimation {
                    target: runner
                    property: "fall"
                    from: 0
                    to: 1
                    duration: 260
                    easing.type: Easing.InQuad
                }
                PauseAnimation {
                    duration: 3800
                }
                NumberAnimation {
                    target: runner
                    property: "opacity"
                    to: 0
                    duration: 700
                }
                ScriptAction {
                    script: root.finished()
                }
            }
            Timer {
                interval: 110
                running: run.running
                repeat: true
                onTriggered: {
                    runner.frame = 1 - runner.frame;
                    if (root.loved) {
                        runner.heartN = (runner.heartN + 1) % hearts.count;
                        hearts.itemAt(runner.heartN).kick(runner.x + runner.width - win.u * 2 + Math.random() * win.u * 6, runner.y + runner.height * (0.25 + Math.random() * 0.6));
                    }
                    if (!runner.jumping) {
                        runner.puffN = (runner.puffN + 1) % dust.count;
                        dust.itemAt(runner.puffN).kick(runner.x + runner.width - win.u * 2, win.ground - win.u * 2);
                    }
                }
            }

            Column {
                id: col
                anchors.horizontalCenter: parent.horizontalCenter
                y: -width / 2 * runner.fall
                spacing: 0
                transform: Rotation {
                    origin.x: col.width / 2
                    origin.y: col.height
                    angle: 90 * runner.fall
                }

                // нимб
                PxIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    bitmap: [".oooooo.", "o......o", ".oooooo."]
                    fill: "#ffd84a"
                    pixel: win.k
                }
                Item {
                    width: 1
                    height: win.u
                }
                // голова — пикселизованная аватарка
                Rectangle {
                    id: headBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: win.k * 12
                    height: win.k * 12
                    color: Theme.dark ? "#000000" : Theme.edge
                    Image {
                        id: face
                        anchors.fill: parent
                        anchors.margins: win.k
                        source: root.cur ? root.cur.avatar || "" : ""
                        sourceSize: Qt.size(10, 10)
                        smooth: false
                        visible: status === Image.Ready
                    }
                    PxIcon {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        bitmap: ["oooooooooo", "oooooooooo", "oo##oo##oo", "oo##oo##oo", "oooooooooo", "oooooooooo", "oo#oooo#oo", "ooo####ooo", "oooooooooo", "oooooooooo"]
                        fill: Theme.accent2
                        pixel: win.k
                    }
                    // хедшот
                    PxIcon {
                        visible: root.headshot
                        anchors.centerIn: parent
                        bitmap: ["...r..r...", ".r.rr.....", "..rrrr.r..", ".rrrrrr...", "r.rrrrr.r.", "..rrrr....", ".r..rr.r..", "....r....."]
                        bad: "#c4141e"
                        pixel: win.k
                    }
                }
                // тело: два кадра бега и прыжок
                PxIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    pixel: win.k
                    bitmap: runner.jumping ? ["..######..", "#oooooooo#", "#.#oooo#.#", "..#oooo#..", "..######..", ".##....##.", "..........", ".........."] : runner.frame ? ["..######..", ".#oooooo#.", "#.#oooo#.#", "..#oooo#..", "..######..", "..#....#..", ".##....##.", "##......##"] : ["..######..", ".#oooooo#.", "#.#oooo#.#", "..#oooo#..", "..######..", "...#..#...", "...#..#...", "..##.##..."]
                }
            }

            // облачко с ником
            PxBox {
                id: bubble
                anchors.bottom: col.top
                anchors.bottomMargin: win.u * 2
                anchors.horizontalCenter: col.horizontalCenter
                width: bubbleRow.implicitWidth + win.u * 8
                height: bubbleRow.implicitHeight + win.u * 5
                color: Theme.face
                Row {
                    id: bubbleRow
                    anchors.centerIn: parent
                    spacing: win.u * 3
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: win.u * 3
                        height: width
                        radius: width / 2
                        color: !root.cur ? "transparent" : root.dead ? "#80848e" : root.cur.voice ? "#5865f2" : root.cur.status === "idle" ? "#f0b232" : root.cur.status === "dnd" ? "#f23f43" : "#23a55a"
                    }
                    PxText {
                        text: !root.cur ? "" : root.note && !root.dead ? root.note : root.dead ? (root.cur.kickable ? root.cur.name + " кикнут из войса!" : root.cur.name + " вышел из сети") : root.cur.voice ? root.cur.name + " в войсе «" + root.cur.voice + "»" : root.cur.name + " в сети!"
                        color: Theme.text
                        font.bold: true
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -bubble.height - win.u * 2
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Gun.chamber && !root.dead ? Qt.OpenHandCursor : Qt.PointingHandCursor
                onPressed: m => {
                    if (m.button === Qt.LeftButton && root.grab())
                        return;
                    const w = Niri.windows.find(w => /discord|equibop|vesktop/i.test(w.app_id || ""));
                    if (w)
                        Niri.focusWindow(w.id);
                }
            }
        }

        // см. RightClickGuard в angelOS (из плагина он не виден)
        MouseArea {
            z: -1
            width: 1
            height: 1
            acceptedButtons: Qt.RightButton
        }
    }
}
