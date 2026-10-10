import QtQuick
import qs.config

// What the demon broke, drawn: glass — pixel cracks spreading from the impact (a Canvas);
// the rest (HellLook.breakageKinds: tv, burn, claws, sigil and the circles' own fog, whirl,
// ooze, coin, ripple, spatter, pitch, frost) — shaders/breakage.frag. One drawing for the
// desktop (ScreenCracks) and the settings' preview of "What she breaks" (previews/Breakage).
Item {
    id: art

    property string kind: "glass"
    property real grow: 0                    // 0..1 how far the cracks have spread
    property real fall: 0                    // 0..1 of the drop (the angel is back)
    property int seed: 1
    property bool weak: false
    property point impact: Qt.point(0.14, 0.92)
    property real clock: 0                   // the shader's clock
    property real veil: 1                    // how much shows (the pointer near: less)
    property int px: Math.max(2, Theme.u * 2)
    readonly property var kinds: HellLook.breakageKinds

    // everything but the glass: a hole in a TV, a burnt hole, claws, a sigil
    ShaderEffect {
        visible: art.kind !== "glass"
        anchors.fill: parent
        opacity: (art.weak ? 0.75 : 1) * art.veil
        fragmentShader: Qt.resolvedUrl("../shaders/breakage.frag.qsb")
        property real kind: art.kinds.indexOf(art.kind)
        property real cells: art.width / art.px
        property real t: art.clock
        property real grow: art.grow
        property real fall: art.fall
        property real seed: art.seed % 997
        property real weak: art.weak ? 1 : 0
        property real ix: art.impact.x
        property real iy: art.impact.y
        property color cEdge: Theme.hellEdge
        property color cRim: Theme.hellRim
        property color cDim: Theme.hellTextDim
        property color cAccent: Theme.hellAccent
    }
    Canvas {
        id: canvas
        visible: art.kind === "glass"
        width: Math.ceil(art.width / art.px)
        height: Math.ceil(art.height / art.px)
        scale: art.px
        transformOrigin: Item.TopLeft
        smooth: false
        antialiasing: false
        renderTarget: Canvas.Image
        opacity: (art.weak ? 0.55 : 0.9) * art.veil * (1 - art.fall)
        y: art.fall * art.fall * art.height * 0.35

        // the crack pattern for this punch: rays from the impact, a few
        // branches and two broken rings, each segment with the moment it appears
        readonly property var segments: {
            let s = art.seed;
            const rnd = () => {
                s = (s * 16807) % 2147483647;
                return (s - 1) / 2147483646;
            };
            const W = width, H = height;
            const cx = Math.round(W * art.impact.x), cy = Math.round(H * art.impact.y);
            const maxR = Math.hypot(W, H) * 0.75;
            const out = [];
            const rays = [];
            const n = art.weak ? 6 : 9;
            for (let i = 0; i < n; i++) {
                let a = -Math.PI * 0.95 + (i + rnd() * 0.6) / n * Math.PI * 1.9;
                let x = cx, y = cy, r = 0;
                const len = maxR * (0.45 + rnd() * 0.55);
                const pts = [[x, y]];
                while (r < len) {
                    a += (rnd() - 0.5) * 0.7;
                    const step = 2 + rnd() * 4;
                    const nx = x + Math.cos(a) * step, ny = y + Math.sin(a) * step;
                    out.push([x, y, nx, ny, r / maxR]);
                    if (rnd() < 0.18) {
                        // a short branch
                        let ba = a + (rnd() < 0.5 ? -1 : 1) * (0.5 + rnd() * 0.6), bx = nx, by = ny;
                        for (let k = 0; k < 3 + rnd() * 4; k++) {
                            const bnx = bx + Math.cos(ba) * 3, bny = by + Math.sin(ba) * 3;
                            out.push([bx, by, bnx, bny, (r + k * 3) / maxR]);
                            bx = bnx;
                            by = bny;
                            ba += (rnd() - 0.5) * 0.6;
                        }
                    }
                    x = nx;
                    y = ny;
                    r = Math.hypot(x - cx, y - cy);
                    pts.push([x, y]);
                }
                rays.push(pts);
            }
            // spider-web rings: join the rays where they cross two radii
            for (const ring of [0.1, 0.24]) {
                const R = maxR * ring;
                const hits = rays.map(p => p.find(q => Math.hypot(q[0] - cx, q[1] - cy) >= R)).filter(q => !!q);
                for (let i = 0; i + 1 < hits.length; i++)
                    if (rnd() < 0.8)
                        out.push([hits[i][0], hits[i][1], hits[i + 1][0], hits[i + 1][1], ring + 0.05]);
            }
            return out;
        }
        readonly property int step: Math.floor(art.grow * 12)
        onStepChanged: requestPaint()
        onSegmentsChanged: requestPaint()
        // the circle's colours change (a new circle): the glass is redrawn in them
        readonly property color tone: Theme.hellTextDim
        onToneChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const g = art.grow;
            // pixel lines (Bresenham): a dark edge under a bright one
            const line = (x0, y0, x1, y1, style, dx, dy) => {
                ctx.fillStyle = style;
                x0 = Math.round(x0);
                y0 = Math.round(y0);
                x1 = Math.round(x1);
                y1 = Math.round(y1);
                const sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
                const ax = Math.abs(x1 - x0), ay = -Math.abs(y1 - y0);
                let err = ax + ay;
                for (let guard = 0; guard < 64; guard++) {
                    ctx.fillRect(x0 + dx, y0 + dy, 1, 1);
                    if (x0 === x1 && y0 === y1)
                        break;
                    const e2 = 2 * err;
                    if (e2 >= ay) {
                        err += ay;
                        x0 += sx;
                    }
                    if (e2 <= ax) {
                        err += ax;
                        y0 += sy;
                    }
                }
            };
            for (const s of segments)
                if (s[4] <= g)
                    line(s[0], s[1], s[2], s[3], Qt.alpha(Theme.hellEdge, 0.7), 1, 1);
            for (const s of segments)
                if (s[4] <= g)
                    line(s[0], s[1], s[2], s[3], Qt.alpha(Theme.hellTextDim, 0.8), 0, 0);
            // the impact: crushed glass
            const cx = Math.round(width * art.impact.x), cy = Math.round(height * art.impact.y);
            ctx.fillStyle = Qt.alpha(Theme.hellText, 0.85);
            for (const d of [[0, 0], [1, 0], [0, 1], [-1, 0], [0, -1], [2, -1], [-1, 2], [1, 1], [-2, -1]])
                ctx.fillRect(cx + d[0], cy + d[1], 1, 1);
        }
    }
}
