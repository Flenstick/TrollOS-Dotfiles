pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets
import "../../widgets/Icons.js" as Icons

// Moves the "active" heart (or the active plate in icon mode) between workspace
// cells with one of several animations. The host gives cell geometry through
// `cellRect(i)` (in this item's coordinates) and asks hosts' cells to look
// inactive while `hiddenIndex` is the destination, so the runner can land there.
//
//   smart   — next/previous workspace: collide, a far jump: ender teleport
//   collide — slow start, a rush, a knock into the next heart (Newton's cradle)
//   ender   — Minecraft enderman teleport: purple particles out, particles in
//   hop     — jumps over in an arc and squashes on landing
//   worm    — a stretchy trail pulls the heart along
//   pixel   — the heart falls apart into pixels that fly over and reassemble
//   beat    — the new heart beats twice with a ripple, the old one deflates
//   sparkle — a comet with a sparkly tail and a starburst
//   drop    — the new heart falls from above and bounces
//   glitch  — RGB-split jumps with NGO interference
//   slide   — a clean slide with a little overshoot
//   off
Item {
    id: a

    property string style: "smart"
    property string sprite: Config.workspaces.sprite || "heart"   // heart | star | cd (WsSprite)
    property real speed: Config.workspaces.heartSpeed > 0 ? Config.workspaces.heartSpeed : 1   // ×: 2 = twice as fast
    property bool vertical: false
    property bool heart: true                // draw a heart runner
    property bool plate: false               // draw the active plate (icon mode)
    property int pixel: Theme.u
    property var cellRect: i => Qt.rect(0, 0, 0, 0)
    property var heartRect: null              // optional: where the heart sits inside a cell
    property color accent: Theme.accent

    readonly property var styles: ["smart", "collide", "ender", "hop", "worm", "pixel", "beat", "sparkle", "drop", "glitch", "slide", "off"]
    property string mode: ""
    property int from: -1
    property int to: -1
    property real t: 1                        // main progress
    property real k: 1                        // impact / landing progress
    property real seed: 0
    readonly property bool running: main.running || impact.running
    readonly property int hiddenIndex: running ? to : -1

    // geometry of this play
    property rect r0: Qt.rect(0, 0, 0, 0)
    property rect r1: Qt.rect(0, 0, 0, 0)
    property rect h0: Qt.rect(0, 0, 0, 0)
    property rect h1: Qt.rect(0, 0, 0, 0)
    readonly property point c0: Qt.point(h0.x + h0.width / 2, h0.y + h0.height / 2)
    readonly property point c1: Qt.point(h1.x + h1.width / 2, h1.y + h1.height / 2)
    readonly property real dist: Math.hypot(c1.x - c0.x, c1.y - c0.y)
    readonly property real dirX: dist > 0 ? (c1.x - c0.x) / dist : 1
    readonly property real dirY: dist > 0 ? (c1.y - c0.y) / dist : 0

    function play(f, tt) {
        const s = styles.includes(style) ? style : "smart";
        if (s === "off" || f < 0 || tt < 0 || f === tt)
            return;
        main.stop();
        impact.stop();
        r0 = cellRect(f);
        r1 = cellRect(tt);
        h0 = heartRect ? heartRect(f) : r0;
        h1 = heartRect ? heartRect(tt) : r1;
        from = f;
        to = tt;
        seed = Math.random() * 1000;
        mode = s === "smart" ? (Math.abs(tt - f) === 1 ? "collide" : "ender") : s;
        const cfg = {
            "collide": [320, [0.72, 0.0, 0.92, 0.32, 1, 1], 200],
            "ender": [620, null, 0],
            "hop": [420, [0.3, 0.0, 0.3, 1.0, 1, 1], 180],
            "worm": [380, null, 0],
            "pixel": [560, null, 0],
            "beat": [560, null, 0],
            "sparkle": [440, [0.2, 0.8, 0.3, 1.0, 1, 1], 260],
            "drop": [460, null, 0],
            "glitch": [300, null, 0],
            "slide": [300, null, 0]
        }[mode];
        const sp = Math.max(0.2, Math.min(4, speed));
        main.duration = Math.round(cfg[0] / sp);
        if (cfg[1]) {
            main.easing.type = Easing.BezierSpline;
            main.easing.bezierCurve = cfg[1];
        } else {
            main.easing.type = Easing.Linear;
        }
        impact.duration = Math.round(cfg[2] / sp);
        t = 0;
        k = 0;
        main.restart();
    }

    NumberAnimation {
        id: main
        target: a
        property: "t"
        from: 0
        to: 1
        onFinished: {
            if (impact.duration > 0)
                impact.restart();
            else
                a.k = 1;
        }
    }
    NumberAnimation {
        id: impact
        target: a
        property: "k"
        from: 0
        to: 1
    }

    // ---- helpers ----
    function lerp(x, y, p) {
        return x + (y - x) * p;
    }
    function clamp01(v) {
        return Math.max(0, Math.min(1, v));
    }
    function outBack(p) {
        const c = 1.70158;
        return 1 + (c + 1) * Math.pow(p - 1, 3) + c * Math.pow(p - 1, 2);
    }
    function outCubic(p) {
        return 1 - Math.pow(1 - p, 3);
    }
    function inCubic(p) {
        return p * p * p;
    }
    function outBounce(p) {
        const n = 7.5625, d = 2.75;
        if (p < 1 / d)
            return n * p * p;
        if (p < 2 / d)
            return n * (p -= 1.5 / d) * p + 0.75;
        if (p < 2.5 / d)
            return n * (p -= 2.25 / d) * p + 0.9375;
        return n * (p -= 2.625 / d) * p + 0.984375;
    }
    function rnd(i, salt) {
        const x = Math.sin((i + 1) * 12.9898 + seed * 0.01 + salt * 78.233) * 43758.5453;
        return x - Math.floor(x);
    }
    // perpendicular to the direction of travel (the free axis of the bar)
    readonly property real px: vertical ? 1 : 0
    readonly property real py: vertical ? 0 : -1

    // ---- runner: where the moving heart is and how it looks ----
    readonly property var runner: {
        const t = a.t, k = a.k;
        let x = c1.x, y = c1.y, sx = 1, sy = 1, o = 1;
        switch (mode) {
        case "collide":
            if (!impact.running && k < 1 && main.running) {
                x = lerp(c0.x, c1.x, t);
                y = lerp(c0.y, c1.y, t);
                // stretches along the way as it speeds up
                const st = 0.35 * Math.pow(t, 3);
                sx = vertical ? 1 - st * 0.5 : 1 + st;
                sy = vertical ? 1 + st : 1 - st * 0.5;
            } else {
                // knocked forward, squashed, wobbles back
                const b = Math.sin(k * Math.PI) * (1 - k) * pixel * 3;
                x = c1.x + dirX * b;
                y = c1.y + dirY * b;
                const sq = 0.3 * Math.pow(1 - k, 2) * Math.cos(k * Math.PI * 3);
                sx = vertical ? 1 + sq : 1 - sq;
                sy = vertical ? 1 - sq : 1 + sq;
            }
            break;
        case "ender":
            if (t < 0.45) {
                const p = t / 0.45;
                x = c0.x + (rnd(Math.floor(t * 40), 1) - 0.5) * pixel * 2;
                y = c0.y + (rnd(Math.floor(t * 40), 2) - 0.5) * pixel * 2;
                sx = sy = 1 - p * 0.8;
                o = (Math.floor(t * 30) % 2 ? 0.35 : 1) * (1 - p * 0.6);
            } else {
                const p = (t - 0.45) / 0.55;
                sx = sy = p < 0.5 ? 0.2 + p * 1.6 : 1 + 0.25 * Math.sin((p - 0.5) * 2 * Math.PI) * (1 - p);
                o = p < 0.6 ? (Math.floor(t * 30) % 2 ? 0.4 : 0.9) : 1;
            }
            break;
        case "hop":
            {
                const h = Math.min(pixel * 9, dist * 0.6 + pixel * 3);
                const arc = 4 * t * (1 - t) * h;
                x = lerp(c0.x, c1.x, t) + px * arc;
                y = lerp(c0.y, c1.y, t) + py * arc;
                if (main.running) {
                    sx = vertical ? 1 : 1 - 0.1 * Math.sin(t * Math.PI);
                    sy = vertical ? 1 - 0.1 * Math.sin(t * Math.PI) : 1 + 0.15 * Math.sin(t * Math.PI);
                } else {
                    const sq = 0.28 * Math.sin(k * Math.PI) * (1 - k * 0.5);
                    sx = 1 + sq;
                    sy = 1 - sq;
                }
            }
            break;
        case "worm":
            x = lerp(c0.x, c1.x, outCubic(t));
            y = lerp(c0.y, c1.y, outCubic(t));
            break;
        case "pixel":
            o = t > 0.92 ? 1 : t < 0.08 ? 1 - t / 0.08 : 0;
            x = t < 0.5 ? c0.x : c1.x;
            y = t < 0.5 ? c0.y : c1.y;
            sx = sy = t > 0.92 ? outBack((t - 0.92) / 0.08) : 1;
            break;
        case "beat":
            {
                // lub-dub
                const b1 = Math.max(0, Math.sin(clamp01(t / 0.3) * Math.PI));
                const b2 = Math.max(0, Math.sin(clamp01((t - 0.35) / 0.3) * Math.PI));
                sx = sy = 1 + 0.38 * b1 + 0.26 * b2;
            }
            break;
        case "sparkle":
            x = lerp(c0.x, c1.x, t);
            y = lerp(c0.y, c1.y, t);
            if (!main.running)
                sx = sy = 1 + 0.25 * Math.sin(k * Math.PI);
            break;
        case "drop":
            {
                const fall = pixel * 14;
                const p = outBounce(t);
                x = c1.x - px * fall * (1 - p);
                y = c1.y - (vertical ? 0 : fall) * (1 - p);
                const land = t > 0.36 ? Math.max(0, Math.sin((t - 0.36) / 0.2 * Math.PI)) * (t < 0.56 ? 1 : 0) : 0;
                sx = 1 + 0.25 * land;
                sy = 1 - 0.2 * land;
            }
            break;
        case "glitch":
            {
                const steps = Math.min(4, Math.floor(t * 5));
                const p = steps / 4;
                x = lerp(c0.x, c1.x, p) + (t < 1 ? (rnd(steps, 3) - 0.5) * pixel * 4 : 0);
                y = lerp(c0.y, c1.y, p);
                o = t < 1 && Math.floor(t * 24) % 3 === 0 ? 0.5 : 1;
            }
            break;
        case "slide":
            x = lerp(c0.x, c1.x, outBack(t));
            y = lerp(c0.y, c1.y, outBack(t));
            break;
        }
        return {
            "x": x,
            "y": y,
            "sx": sx,
            "sy": sy,
            "o": o
        };
    }

    // ---- the trail of the worm ----
    Rectangle {
        visible: a.running && a.mode === "worm"
        readonly property real lead: a.outCubic(a.t)
        readonly property real tail: a.inCubic(a.t)
        readonly property real thick: a.pixel * 4
        x: a.vertical ? a.c0.x - thick / 2 : Math.min(a.lerp(a.c0.x, a.c1.x, lead), a.lerp(a.c0.x, a.c1.x, tail))
        y: a.vertical ? Math.min(a.lerp(a.c0.y, a.c1.y, lead), a.lerp(a.c0.y, a.c1.y, tail)) : a.c0.y - thick / 2
        width: a.vertical ? thick : Math.abs(a.lerp(a.c0.x, a.c1.x, lead) - a.lerp(a.c0.x, a.c1.x, tail)) + thick
        height: a.vertical ? Math.abs(a.lerp(a.c0.y, a.c1.y, lead) - a.lerp(a.c0.y, a.c1.y, tail)) + thick : thick
        color: Qt.alpha(a.accent, 0.55)
        radius: thick / 2
    }

    // ---- the old heart deflating / floating away (beat, drop) ----
    WsSprite {
        visible: a.running && a.heart && (a.mode === "beat" || a.mode === "drop")
        readonly property real p: a.clamp01(a.t / 0.6)
        sprite: a.sprite
        lit: true
        playful: false
        pixel: a.pixel
        fill: a.accent
        x: a.c0.x - width / 2 + a.px * a.pixel * 8 * p * (a.mode === "drop" ? 1 : 0)
        y: a.c0.y - height / 2 + a.py * a.pixel * 8 * p * (a.mode === "drop" ? 1 : 0)
        scale: 1 - 0.3 * p
        opacity: 1 - p
    }

    // ---- ripple ring (beat) ----
    Rectangle {
        visible: a.running && a.mode === "beat"
        readonly property real p: a.clamp01((a.t - 0.1) / 0.8)
        width: a.pixel * (10 + 22 * p)
        height: width
        radius: width / 2
        x: a.c1.x - width / 2
        y: a.c1.y - height / 2
        color: "transparent"
        border.width: a.pixel
        border.color: a.accent
        opacity: 0.8 * (1 - p)
    }

    // ---- active plate (icon mode) ----
    Rectangle {
        visible: a.running && a.plate
        readonly property real p: a.mode === "slide" ? a.outBack(a.t) : a.mode === "worm" ? a.outCubic(a.t) : a.mode === "pixel" || a.mode === "ender" || a.mode === "beat" || a.mode === "drop" ? (a.t < 0.5 ? 0 : 1) : a.mode === "glitch" ? Math.min(4, Math.floor(a.t * 5)) / 4 : a.t
        x: a.lerp(a.r0.x, a.r1.x, p) + (a.runner.x - a.lerp(a.c0.x, a.c1.x, p)) * 0.5
        y: a.lerp(a.r0.y, a.r1.y, p) + a.pixel
        width: a.lerp(a.r0.width, a.r1.width, p)
        height: a.lerp(a.r0.height, a.r1.height, p) - a.pixel * 2
        color: Qt.alpha(a.accent, 0.28)
        border.width: Math.max(1, a.pixel / 2)
        border.color: a.accent
        opacity: a.runner.o
    }

    // ---- glitch copies ----
    Repeater {
        model: a.running && a.mode === "glitch" && a.heart ? [
            {
                "c": "#00e5ff",
                "d": -1
            },
            {
                "c": "#ff2bd6",
                "d": 1
            }
        ] : []
        WsSprite {
            required property var modelData
            sprite: a.sprite
            playful: false
            pixel: a.pixel
            tone: modelData.c
            fill: modelData.c
            ink: modelData.c
            opacity: 0.55 * (1 - a.t)
            x: a.runner.x - width / 2 + modelData.d * a.pixel * 2 * (Math.floor(a.t * 20) % 2 ? 1 : -0.5)
            y: a.runner.y - height / 2
        }
    }

    // ---- the runner heart ----
    WsSprite {
        id: runnerHeart
        visible: a.running && a.heart
        sprite: a.sprite
        lit: true
        playful: false
        pixel: a.pixel
        fill: a.accent
        x: a.runner.x - width / 2
        y: a.runner.y - height / 2
        opacity: a.runner.o
        transform: Scale {
            origin.x: runnerHeart.width / 2
            origin.y: runnerHeart.height / 2
            xScale: a.runner.sx
            yScale: a.runner.sy
        }
    }

    // ---- particles ----
    // ender: purple portal bits; pixel: the heart's own pixels; sparkle: stars;
    // collide: an impact burst
    readonly property int particleCount: mode === "pixel" ? 30 : mode === "ender" ? 24 : 14
    Repeater {
        model: a.running && (a.mode === "ender" || a.mode === "pixel" || a.mode === "sparkle" || a.mode === "collide") ? a.particleCount : 0
        Rectangle {
            id: bit
            required property int index
            readonly property var s: a.particle(index)
            visible: s.o > 0.01
            x: s.x - width / 2
            y: s.y - height / 2
            width: s.size
            height: s.size
            color: s.c
            opacity: s.o
            rotation: s.rot || 0
        }
    }

    // the sprite's bitmap cells, for the pixel style
    readonly property var heartCells: {
        const rows = Icons.get(sprite === "star" ? "sparkleStar" : sprite === "cd" ? "cd" : "heart");
        const w = rows[0].length, h = rows.length;
        const colors = {
            "o": a.accent,
            "x": Theme.accent2,
            "y": Theme.accent3,
            "w": "#ffffff"
        };
        const cells = [];
        for (let yy = 0; yy < h; yy++)
            for (let xx = 0; xx < rows[yy].length; xx++)
                if (rows[yy][xx] !== ".")
                    cells.push({
                        "x": xx - (w - 1) / 2,
                        "y": yy - (h - 1) / 2,
                        "ink": rows[yy][xx] === "#",
                        "c": colors[rows[yy][xx]] || a.accent
                    });
        return cells;
    }

    function particle(i) {
        const t = a.t, k = a.k;
        const r1 = rnd(i, 1), r2 = rnd(i, 2), r3 = rnd(i, 3);
        if (mode === "ender") {
            // half burst out of the old spot, half gather into the new one
            const purple = ["#cc00fa", "#e079fa", "#7a1cac", "#b429f9"][i % 4];
            const out = i % 2 === 0;
            const ang = r1 * Math.PI * 2;
            const reach = pixel * (5 + r2 * 9);
            let p, x, y, o;
            if (out) {
                p = clamp01(t / 0.6 - r3 * 0.2);
                x = c0.x + Math.cos(ang) * reach * outCubic(p);
                y = c0.y + Math.sin(ang) * reach * 0.6 * outCubic(p) - pixel * 5 * p;   // drift up like portal bits
                o = p > 0 && p < 1 ? 1 - p : 0;
            } else {
                p = clamp01((t - 0.3) / 0.55 - r3 * 0.15);
                x = c1.x + Math.cos(ang) * reach * (1 - outCubic(p));
                y = c1.y + Math.sin(ang) * reach * 0.6 * (1 - outCubic(p)) - pixel * 2 * (1 - p);
                o = p > 0 && p < 1 ? Math.min(1, p * 3) * (1 - p * 0.6) : 0;
            }
            return {
                "x": x,
                "y": y,
                "size": pixel * (r2 > 0.6 ? 2 : 1),
                "c": purple,
                "o": o * (Math.floor((t + r1) * 40) % 3 === 0 ? 0.4 : 1)
            };
        }
        if (mode === "pixel") {
            const cells = heartCells;
            const cell = cells[Math.floor(i * cells.length / particleCount) % cells.length];
            const d = r1 * 0.3;
            const p = clamp01((t - d) / 0.6);
            const e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;   // in-out quad
            // a curved path: control point pushed off the axis
            const mx = (c0.x + c1.x) / 2 + px * pixel * (6 + r2 * 10), my = (c0.y + c1.y) / 2 + py * pixel * (6 + r2 * 10);
            const sx = c0.x + cell.x * pixel, sy = c0.y + cell.y * pixel;
            const ex = c1.x + cell.x * pixel, ey = c1.y + cell.y * pixel;
            const x = (1 - e) * (1 - e) * sx + 2 * (1 - e) * e * mx + e * e * ex;
            const y = (1 - e) * (1 - e) * sy + 2 * (1 - e) * e * my + e * e * ey;
            return {
                "x": x,
                "y": y,
                "size": pixel,
                "c": cell.ink ? Theme.edge : cell.c,
                "o": t < 0.95 ? 1 : 1 - (t - 0.95) / 0.05
            };
        }
        if (mode === "sparkle") {
            if (main.running) {
                // the comet tail
                const lag = (i + 1) * 0.045;
                const p = clamp01(t - lag);
                return {
                    "x": lerp(c0.x, c1.x, p) + (r1 - 0.5) * pixel * 3,
                    "y": lerp(c0.y, c1.y, p) + (r2 - 0.5) * pixel * 3,
                    "size": pixel * (i < 4 ? 2 : 1),
                    "c": i % 3 === 0 ? "#ffffff" : i % 3 === 1 ? Theme.accent3 : a.accent,
                    "o": t > lag ? (1 - i / particleCount) * 0.9 : 0,
                    "rot": 45
                };
            }
            const ang = i / particleCount * Math.PI * 2 + r1 * 0.3;
            const reach = pixel * (6 + r2 * 6) * outCubic(k);
            return {
                "x": c1.x + Math.cos(ang) * reach,
                "y": c1.y + Math.sin(ang) * reach,
                "size": pixel * (r3 > 0.5 ? 2 : 1),
                "c": i % 2 ? "#ffffff" : Theme.accent3,
                "o": (1 - k) * (Math.floor(k * 16 + i) % 2 ? 1 : 0.5),
                "rot": 45
            };
        }
        // collide: a small burst where the hearts meet
        if (main.running)
            return {
                "x": 0,
                "y": 0,
                "size": 0,
                "c": "transparent",
                "o": 0
            };
        const hit = Qt.point(c1.x - dirX * pixel * 4, c1.y - dirY * pixel * 4);
        const ang = (i / particleCount - 0.5) * Math.PI * 1.4 + Math.atan2(-dirY, -dirX) + (r1 - 0.5) * 0.4;
        const reach = pixel * (3 + r2 * 6) * outCubic(k);
        return {
            "x": hit.x + Math.cos(ang) * reach,
            "y": hit.y + Math.sin(ang) * reach,
            "size": pixel * (r3 > 0.6 ? 2 : 1),
            "c": i % 3 === 0 ? "#ffffff" : i % 3 === 1 ? Theme.accent3 : a.accent,
            "o": 1 - k
        };
    }
}
