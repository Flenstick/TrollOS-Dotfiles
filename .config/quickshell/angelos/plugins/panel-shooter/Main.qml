pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import "."
import "Sprites.js" as Sprites

// «Тир на панели»: стрельба по друзьям из Discord, которые пробегают по панели
// (плагин friend-runner регистрирует их в Gun.targets), и, по желанию, по
// случайным человечкам. Пока пистолет
// в руке, полоса над панелью ловит мышь: ЛКМ — выстрел, ПКМ / R — перезарядка,
// Esc / СКМ — убрать пистолет. Без пистолета слой прозрачен для мыши — кроме
// самих человечков, если включена «Пыточная» (torture-room): их можно схватить.
Item {
    id: root

    property var plugin

    readonly property bool sound: plugin ? plugin.get("sound", true) : true
    readonly property real volume: plugin ? plugin.get("volume", 0.6) : 0.6
    // random people besides the Discord friends (off by default)
    readonly property bool randoms: plugin ? plugin.get("randoms", false) : false
    readonly property bool ambient: plugin ? plugin.get("ambient", true) : true
    readonly property int ambientEvery: plugin ? plugin.get("ambientEvery", 15) : 15
    readonly property int crowd: plugin ? plugin.get("crowd", 5) : 5
    readonly property bool busy: Gun.armed || people.count > 0 || drops.count > 0 || floaters.count > 0

    property real now: Date.now()
    property int nextId: 1
    property real aimX: -1000
    property real aimY: -1000
    property bool aiming: false

    // all-time stats live in the plugin settings (they load after the plugin starts)
    Binding {
        target: Gun
        property: "totalKills"
        value: root.plugin ? root.plugin.get("kills", 0) : 0
    }
    Binding {
        target: Gun
        property: "totalHeadshots"
        value: root.plugin ? root.plugin.get("headshots", 0) : 0
    }
    Component.onDestruction: Gun.armed = false

    Connections {
        target: Gun
        function onArmedChanged() {
            if (!Gun.armed)
                return;
            keys.forceActiveFocus();
            if (spawner.running) {
                spawner.interval = 400;
                spawner.restart();
            }
        }
        function onWaveRequested(count) {
            for (let i = 0; i < count; i++)
                root.spawn(i * 40);
        }
        // the torture room let someone of ours go: they land where they were dropped and flee
        function onVictimReleased(v, info) {
            if (v.owner !== "panel-shooter")
                return;
            const now = Date.now();
            people.append({
                "pid": root.nextId++,
                "x": (info.x || win.width / 2) - win.sw / 2,
                "dir": Math.random() < 0.5 ? 1 : -1,
                "speed": 150 * win.u / 2,
                "dist": 0,
                "state": 0,
                "at": 0,
                "head": false,
                "panicUntil": now + 60000,
                "scream": info.broken ? "МАМОЧКИ…" : Sprites.pick(["СВОБОДА!", "БЕЖИМ!", "Я ВСЁ РАССКАЖУ!", "ПСИХ!"]),
                "hair": v.hair,
                "shirt": v.shirt,
                "pants": v.pants,
                "skin": v.skin
            });
        }
        function onStatsReset() {
            Gun.shots = Gun.hits = Gun.kills = 0;
            root.plugin.set("kills", 0);
            root.plugin.set("headshots", 0);
        }
    }

    // the Geiger counter from the same case
    Geiger {
        id: geiger
        plugin: root.plugin
        sound: root.sound
        volume: root.volume
    }

    IpcHandler {
        target: "shooter"
        function geiger(): void {
            Gun.toggleGeiger();
        }
        // what the counter reads at a point of the screen (logical px)
        function dose(x: real, y: real): string {
            const r = geiger.measure(x, y);
            return JSON.stringify({
                "usv": +(r.cps * geiger.usvPerCps).toFixed(2),
                "cps": +r.cps.toFixed(1),
                "source": r.source,
                "windows": geiger.rects.map(w => w.win.app_id + " " + [w.x, w.y, w.w, w.h].map(Math.round).join(",")),
                "isotopes": geiger.isotopes.map(i => i.name + " " + Math.round(i.x) + "," + Math.round(i.y) + (i.found ? " found" : ""))
            });
        }
        function arm(): void {
            Gun.take();
        }
        function holster(): void {
            Gun.holster();
        }
        function toggle(): void {
            Gun.toggle();
        }
        function wave(): void {
            Gun.waveRequested(6);
        }
        // fire at the first person on the panel (head or body)
        function test(head: bool): string {
            for (let i = 0; i < people.count; i++) {
                const p = people.get(i);
                if (p.state === 0 && p.x > 0 && p.x < win.width - win.sw) {
                    root.fire(p.x + win.sw / 2, win.ground - win.sh + (head ? win.k * 3 : win.k * 8));
                    return "shot at " + Math.round(p.x);
                }
            }
            // a Discord friend: sweep the panel at chest / head height
            const fromBottom = win.barH + win.k * (head ? 15 : 5);
            const sweep = win.screen ? win.screen.width : win.width;
            for (let x = 0; x < sweep; x += win.k) {
                const r = Gun.hitTest(x, fromBottom);
                if (r) {
                    root.now = Date.now();
                    play(shotSfx.objectAt(0));
                    root.hitEffects(r.head, x, win.height - fromBottom, -1, r.name);
                    return "shot friend " + r.name + (r.head ? " (head)" : "");
                }
            }
            return "nobody on the panel";
        }
        // hand the first person on the panel to the torture room
        function grab(): string {
            for (let i = 0; i < people.count; i++) {
                const p = people.get(i);
                if (p.state === 0 && p.x > 0 && p.x < win.width - win.sw) {
                    root.grab(p.pid);
                    return Gun.victim ? "grabbed" : "torture room is off";
                }
            }
            return "nobody on the panel";
        }
        function stats(): string {
            return JSON.stringify({
                "armed": Gun.armed,
                "targets": Gun.targets.length,
                "ammo": Gun.ammo,
                "kills": Gun.totalKills,
                "headshots": Gun.totalHeadshots,
                "sessionShots": Gun.shots,
                "sessionHits": Gun.hits
            });
        }
    }

    // ---- people ----
    ListModel {
        id: people
    }
    ListModel {
        id: drops       // blood
    }
    ListModel {
        id: floaters    // "+1" / "ХЕДШОТ!"
    }

    function aliveCount() {
        let n = 0;
        for (let i = 0; i < people.count; i++)
            if (people.get(i).state === 0)
                n++;
        return n;
    }

    function spawn(offset) {
        if (!win.width)
            return;
        const dir = Math.random() < 0.5 ? 1 : -1;
        const fast = Math.random() < 0.3;
        const lag = (offset || 0) + Math.random() * win.u * 20;
        people.append({
            "pid": nextId++,
            "x": dir > 0 ? -win.sw - lag : win.width + lag,
            "dir": dir,
            "speed": (fast ? 130 + Math.random() * 60 : 45 + Math.random() * 45) * win.u / 2,
            "dist": Math.random() * 100,
            "state": 0,
            "at": 0,
            "head": false,
            "panicUntil": 0,
            "scream": "",
            "hair": Sprites.pick(Sprites.HAIR),
            "shirt": Sprites.pick(Sprites.SHIRTS),
            "pants": Sprites.pick(Sprites.PANTS),
            "skin": Sprites.pick(Sprites.SKIN)
        });
    }

    Timer {
        id: spawner
        running: !!root.plugin && root.randoms && (Gun.armed || root.ambient)
        repeat: true
        interval: 4000
        onTriggered: {
            const cap = Gun.armed ? root.crowd : 2;
            if (root.aliveCount() < cap)
                root.spawn(0);
            interval = Gun.armed ? 600 + Math.random() * 1800 : root.ambientEvery * 1000 * (0.5 + Math.random());
        }
    }

    // ---- gun ----
    function play(effect) {
        if (sound)
            effect.play();
    }

    function fire(mx, my) {
        if (Gun.reloading)
            return;
        if (Gun.ammo <= 0) {
            play(emptySfx);
            reload();
            return;
        }
        now = Date.now();
        Gun.ammo--;
        Gun.shots++;
        Gun.lastShot = now;
        play(shotSfx.objectAt(Gun.shots % shotSfx.count));

        // Discord friends first (friend-runner), then the random people
        const friend = Gun.hitTest(mx, win.height - my);
        if (friend)
            hitEffects(friend.head, mx, my, -1, friend.name);
        const pad = win.k;
        for (let i = people.count - 1; i >= 0 && !friend; i--) {
            const p = people.get(i);
            if (p.state !== 0)
                continue;
            const top = win.ground - win.sh;
            if (mx >= p.x - pad && mx <= p.x + win.sw + pad && my >= top - pad && my <= win.ground) {
                kill(i, my < top + Sprites.HEAD_ROWS * win.k, mx, my);
                break;
            }
        }
        // everybody close enough to hear it panics, some turn back
        for (let i = 0; i < people.count; i++) {
            const p = people.get(i);
            if (p.state !== 0 || Math.abs(p.x + win.sw / 2 - mx) > win.u * 350)
                continue;
            if (p.panicUntil < now) {
                if (Math.random() < 0.35)
                    people.setProperty(i, "dir", -p.dir);
                people.setProperty(i, "scream", Math.random() < 0.6 ? Sprites.pick(Sprites.SCREAMS) : "");
            }
            people.setProperty(i, "panicUntil", now + 2200 + Math.random() * 1200);
        }
        if (Gun.ammo === 0)
            autoReload.restart();
    }

    // hand a running person over to the torture room
    function grab(pid) {
        for (let i = 0; i < people.count; i++) {
            const p = people.get(i);
            if (p.pid !== pid || p.state !== 0)
                continue;
            if (Gun.grab({
                    "owner": "panel-shooter",
                    "kind": "random",
                    "hair": p.hair,
                    "shirt": p.shirt,
                    "pants": p.pants,
                    "skin": p.skin,
                    "dir": p.dir,
                    "sx": p.x + win.sw / 2,
                    "sy": (win.screen ? win.screen.height : win.height) - win.barH
                }))
                people.remove(i);
            return;
        }
    }

    function kill(i, head, mx, my) {
        hitTimer.restart();
        people.setProperty(i, "state", 1);
        people.setProperty(i, "at", now);
        people.setProperty(i, "head", head);
        hitEffects(head, mx, my, people.get(i).dir, "");
    }

    function hitEffects(head, mx, my, dir, name) {
        Gun.hits++;
        Gun.kills++;
        if (plugin) {
            plugin.set("kills", plugin.get("kills", 0) + 1);
            if (head)
                plugin.set("headshots", plugin.get("headshots", 0) + 1);
        }
        const n = head ? 16 : 10;
        for (let j = 0; j < n; j++)
            drops.append({
                "x": mx,
                "y": my,
                "vx": (dir * 0.6 + (Math.random() - 0.5) * 1.6) * win.u * 60,
                "vy": -(0.4 + Math.random()) * win.u * 90,
                "at": now,
                "landed": false
            });
        floaters.append({
            "x": mx,
            "y": name ? my - win.u * 18 : win.ground - win.sh - win.u * 4,
            "text": head ? I18n.t("ХЕДШОТ!", "HEADSHOT!") : "+1",
            "head": head,
            "at": now
        });
        play(hitSfx);
    }

    function reload() {
        if (Gun.reloading || Gun.ammo === Gun.magSize)
            return;
        Gun.reloading = true;
        play(reloadSfx);
        reloadDone.restart();
    }
    Timer {
        id: autoReload
        interval: 350
        onTriggered: root.reload()
    }
    Timer {
        id: reloadDone
        interval: 750
        onTriggered: {
            Gun.ammo = Gun.magSize;
            Gun.reloading = false;
        }
    }

    Instantiator {
        id: shotSfx
        model: 3
        delegate: SoundEffect {
            source: root.plugin ? root.plugin.url("sfx/shot.wav") : ""
            volume: root.volume
        }
    }
    SoundEffect {
        id: hitSfx
        source: root.plugin ? root.plugin.url("sfx/hit.wav") : ""
        volume: root.volume
    }
    SoundEffect {
        id: emptySfx
        source: root.plugin ? root.plugin.url("sfx/empty.wav") : ""
        volume: root.volume
    }
    SoundEffect {
        id: reloadSfx
        source: root.plugin ? root.plugin.url("sfx/reload.wav") : ""
        volume: root.volume
    }

    // ---- the strip above the panel ----
    PanelWindow {
        id: win

        readonly property int u: Theme.u
        readonly property int k: Math.max(2, Math.round(Theme.u * 1.5))   // one pixel of a person
        readonly property bool island: (Config.bar.screens || []).includes("dynamic-island")
        // the people walk on the roof of the taskbar, otherwise along the screen edge
        readonly property int barH: island ? u * 2 : Config.bar.style === "taskbar" ? u * 20 : u * 2
        readonly property int ground: height - barH
        readonly property int sw: Sprites.W * k
        readonly property int sh: Sprites.H * k

        screen: Shell.focusedScreen
        visible: root.busy
        anchors {
            bottom: true
            left: true
            right: true
        }
        implicitHeight: barH + u * 75
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        // no gun: clicks go straight through to whatever is below, except the
        // people themselves while the torture room is on (they can be grabbed)
        mask: Region {
            item: Gun.armed ? field : null
            regions: Gun.armed || !Gun.chamber ? [] : win.hitRegions
        }
        property var hitRegions: []
        function updateHits() {
            const old = hitRegions;
            const list = [];
            for (let i = 0; i < manRep.count; i++) {
                const it = manRep.itemAt(i);
                if (it && !it.dead)
                    list.push(regionComp.createObject(win, {
                        "item": it
                    }));
            }
            hitRegions = list;
            old.forEach(r => r.destroy());
        }
        Component {
            id: regionComp
            Region {}
        }
        Timer {
            id: hitTimer
            interval: 0
            onTriggered: win.updateHits()
        }
        WlrLayershell.namespace: "angelos-shooter"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: Gun.armed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        FrameAnimation {
            running: win.visible
            onTriggered: {
                const dt = Math.min(frameTime, 0.05);
                const now = root.now = Date.now();
                const g = win.u * 450;
                for (let i = people.count - 1; i >= 0; i--) {
                    const p = people.get(i);
                    if (p.state === 0) {
                        const v = p.speed * (p.panicUntil > now ? 2.3 : 1) * dt;
                        const nx = p.x + p.dir * v;
                        if ((p.dir > 0 && nx > win.width + win.sw) || (p.dir < 0 && nx < -win.sw * 2))
                            people.remove(i);
                        else {
                            people.setProperty(i, "x", nx);
                            people.setProperty(i, "dist", p.dist + v);
                        }
                    } else if (now - p.at > 5200) {
                        people.remove(i);
                    }
                }
                for (let i = drops.count - 1; i >= 0; i--) {
                    const d = drops.get(i);
                    if (now - d.at > 3500) {
                        drops.remove(i);
                        continue;
                    }
                    if (d.landed)
                        continue;
                    let y = d.y + d.vy * dt;
                    if (y >= win.ground - win.k) {
                        drops.setProperty(i, "y", win.ground - win.k);
                        drops.setProperty(i, "landed", true);
                        continue;
                    }
                    drops.setProperty(i, "x", d.x + d.vx * dt);
                    drops.setProperty(i, "y", y);
                    drops.setProperty(i, "vy", d.vy + g * dt);
                }
                for (let i = floaters.count - 1; i >= 0; i--)
                    if (now - floaters.get(i).at > 1000)
                        floaters.remove(i);
            }
        }

        Item {
            id: field
            width: parent.width
            height: win.ground

            // a faint glow marks the zone that eats clicks while the gun is out
            Rectangle {
                anchors.fill: parent
                visible: Gun.armed
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.danger, 0.13)
                    }
                }
            }
        }

        // blood puddles under the bodies
        Repeater {
            model: people
            Rectangle {
                id: puddle
                required property var model
                readonly property real grow: model.state === 1 ? Math.min(1, (root.now - model.at - 200) / 1400) : 0
                visible: grow > 0
                width: win.sh * 1.2 * grow
                height: win.k
                x: model.x + win.sw / 2 - model.dir * win.sh / 2 - width / 2
                y: win.ground - height
                color: "#8e0f16"
                opacity: Math.max(0, Math.min(1, (5200 - (root.now - model.at)) / 800))
            }
        }

        // the people
        Repeater {
            id: manRep
            model: people
            onItemAdded: hitTimer.restart()
            onItemRemoved: hitTimer.restart()
            Item {
                id: man
                required property var model
                readonly property bool dead: model.state === 1
                readonly property real since: root.now - model.at
                readonly property real fall: dead ? Math.min(1, since / 260) : 0
                readonly property bool panic: !dead && model.panicUntil > root.now
                x: Math.round(model.x)
                y: win.ground - height
                width: win.sw
                height: win.sh
                opacity: dead ? Math.max(0, Math.min(1, (5200 - since) / 800)) : 1

                PxIcon {
                    id: body
                    y: -win.sw / 2 * man.fall + (man.panic && Math.floor(man.model.dist / (win.k * 6)) % 2 ? -win.k : 0)
                    pixel: win.k
                    bitmap: man.dead ? (man.model.head ? Sprites.DEAD_HEAD : Sprites.DEAD) : Math.floor(man.model.dist / (win.k * 6)) % 2 ? Sprites.RUN_A : Sprites.RUN_B
                    mirror: man.model.dir < 0
                    ink: man.model.hair
                    fill: man.model.shirt
                    fill2: man.model.pants
                    fill3: man.model.skin
                    bad: "#c4141e"
                    // falls on its back
                    transform: Rotation {
                        origin.x: body.width / 2
                        origin.y: body.height
                        angle: -man.model.dir * 90 * man.fall
                    }
                }

                // scream / "!"
                PxText {
                    visible: man.panic
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    anchors.bottomMargin: win.u
                    text: man.model.scream || "!"
                    kind: "tiny"
                    font.bold: true
                    color: "#ffffff"
                    style: Text.Outline
                    styleColor: "#000000"
                }

                // grab (no gun in hand): off to the torture room
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -win.k
                    enabled: !Gun.armed && Gun.chamber && !man.dead
                    cursorShape: Qt.OpenHandCursor
                    onPressed: root.grab(man.model.pid)
                }

                // the soul leaves
                PxIcon {
                    readonly property real t: (man.since - 500) / 2000
                    visible: man.dead && t > 0 && t < 1
                    x: win.sw / 2 - man.model.dir * win.sh / 2 - width / 2 + Math.sin(t * 9) * win.u * 2
                    y: win.sh - win.sw / 2 - height - t * win.u * 40
                    name: "ghost"
                    pixel: win.u
                    fill: "#ffffff"
                    opacity: (1 - t) * 0.85
                }
            }
        }

        Repeater {
            model: drops
            Rectangle {
                required property var model
                x: model.x
                y: model.y
                width: model.landed ? win.k * 2 : win.k
                height: win.k
                color: "#b3131b"
                opacity: Math.max(0, Math.min(1, (3500 - (root.now - model.at)) / 700))
            }
        }

        Repeater {
            model: floaters
            PxText {
                required property var model
                readonly property real t: (root.now - model.at) / 1000
                x: model.x - width / 2
                y: model.y - t * win.u * 18
                opacity: 1 - t
                text: model.text
                kind: model.head ? "title" : "body"
                font.bold: true
                color: model.head ? "#ffd84a" : "#ffffff"
                style: Text.Outline
                styleColor: "#000000"
            }
        }

        // ---- the hand with the pistol, crosshair, HUD ----
        Item {
            id: hand
            readonly property real kick: Math.max(0, 1 - (root.now - Gun.lastShot) / 140)
            visible: Gun.armed && root.aiming
            x: root.aimX + win.k * 5 + kick * win.k * 3
            y: root.aimY + win.k * 4 + kick * win.k * 2
            width: gunSprite.width
            height: gunSprite.height
            rotation: 32 + kick * 22 + (Gun.reloading ? 40 : 0)
            transformOrigin: Item.TopLeft
            Behavior on rotation {
                enabled: !hand.kick
                NumberAnimation {
                    duration: 120
                }
            }

            PxIcon {
                id: gunSprite
                bitmap: Sprites.GUN_HAND
                pixel: win.k
                mirror: true
                ink: "#15161a"
                body: "#3d4049"
                light: "#9aa1ad"
                fill: "#2f4e8a"
                fill3: "#f0c6a0"
            }
            PxIcon {
                visible: root.now - Gun.lastShot < 70
                anchors.right: parent.left
                anchors.top: parent.top
                anchors.topMargin: -win.k
                bitmap: Sprites.FLASH
                pixel: win.k
                mirror: true
                fill3: "#ffd84a"
                light: "#ffffff"
            }
        }

        Item {
            visible: Gun.armed && root.aiming
            x: root.aimX - width / 2
            y: root.aimY - height / 2
            width: cross.width
            height: cross.height
            scale: 1 + Math.max(0, 1 - (root.now - Gun.lastShot) / 150) * 0.6
            PxIcon {
                x: win.u / 2 + 1
                y: win.u / 2 + 1
                bitmap: Sprites.CROSS
                pixel: win.u
                light: "#000000"
                bad: "#000000"
                opacity: 0.55
            }
            PxIcon {
                id: cross
                bitmap: Sprites.CROSS
                pixel: win.u
                light: "#ffffff"
                bad: "#ff2a2a"
            }
        }

        PxBox {
            id: hud
            visible: Gun.armed
            anchors.right: parent.right
            anchors.rightMargin: win.u * 6
            anchors.bottom: field.bottom
            anchors.bottomMargin: win.u * 3
            width: hudRow.implicitWidth + win.u * 8
            height: hudRow.implicitHeight + win.u * 4
            color: Qt.alpha(Theme.face, 0.92)
            Row {
                id: hudRow
                anchors.centerIn: parent
                spacing: win.u * 4
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: win.u
                    Repeater {
                        model: Gun.magSize
                        PxIcon {
                            required property int index
                            bitmap: Sprites.BULLET
                            pixel: win.u
                            fill: "#c98a2e"
                            fill3: "#e8c46a"
                            opacity: index < Gun.ammo ? 1 : 0.2
                        }
                    }
                }
                PxText {
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "tiny"
                    text: Gun.reloading ? I18n.t("перезарядка…", "reloading…") : I18n.t("убито: ", "kills: ") + Gun.kills + "   " + I18n.t("ПКМ/R — перезарядка · Esc — убрать", "RMB/R — reload · Esc — holster")
                }
            }
        }

        MouseArea {
            anchors.fill: field
            enabled: Gun.armed
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Gun.armed ? Qt.BlankCursor : Qt.ArrowCursor
            onContainsMouseChanged: root.aiming = containsMouse
            onPositionChanged: m => {
                root.aimX = m.x;
                root.aimY = m.y;
            }
            onPressed: m => {
                root.aimX = m.x;
                root.aimY = m.y;
                keys.forceActiveFocus();
                if (m.button === Qt.LeftButton)
                    root.fire(m.x, m.y);
                else if (m.button === Qt.RightButton)
                    root.reload();
                else
                    Gun.holster();
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape)
                    Gun.holster();
                else if (e.key === Qt.Key_R || e.text.toLowerCase() === "к")
                    root.reload();
                else
                    return;
                e.accepted = true;
            }
        }

        // see RightClickGuard in angelOS (not importable from a plugin)
        MouseArea {
            z: -1
            width: 1
            height: 1
            acceptedButtons: Qt.RightButton
        }
    }
}
