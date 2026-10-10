pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.background.circles

// Heaven's look of RadialMenu: wings. A halo hangs over the pointer and two wings unfold from
// under it; every entry is a long feather, row by row — left, then right (1 is the top left,
// 2 the top right…) — the longest at the top like a wing's primaries, small coverts over where
// they start. The icon sits near the feather's tip, the name beside it outside the wing; the
// one you're on lifts out of the wing. A flyout opens past the wing's tip. Keys: ←/→ to the
// other wing (outwards opens a flyout), ↑/↓ along one wing. The middle (the logo under the
// halo) closes. Pale feathers in any palette, in pixels of the shell's size: each wing is one
// picture painted once, it only turns from the shoulder (and overshoots, a flap) as it opens.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property int rows: Math.ceil(n / 2)
    readonly property int px: Math.max(1, Math.round(Theme.u * k))         // the feathers' pixel
    readonly property real tip: Math.round(Theme.u * 18 * k)                // room for an icon
    readonly property real step: tip + Math.round(Theme.u * 5 * k)          // tip to tip down the wing
    readonly property real thick: Math.round(step * 1.3)                   // a feather's width
    // on a narrow screen (a portrait one at a big scale) the feathers get shorter, so both
    // wings and their names still fit
    readonly property real room: width / 2 - Theme.u * 4 - (shoulderX + lift + tip * 0.6 + labelGap + labelW + Theme.u * 2)
    readonly property real longest: Math.min(Math.round(Theme.u * 84 * k), Math.max(tip * 2, Math.floor(room)))
    readonly property real shortest: Math.min(Math.round(Theme.u * 50 * k), Math.round(longest * 0.6))
    readonly property real hub: Math.round(Theme.u * 22 * k)
    readonly property real lift: px * 4                                     // how far the one you're on comes out
    // the wings grow from the halo's sides, a little above the pointer
    readonly property real shoulderX: Math.round(hub * 0.4)
    readonly property real shoulderY: -Math.round(step * 0.35)
    readonly property real labelGap: Theme.u * 2
    readonly property real labelW: menu.labels ? Math.ceil(metrics.width) + Theme.u * 2 : 0
    readonly property real reachX: shoulderX + longest + lift + tip * 0.6 + labelGap + labelW + Theme.u * 2
    readonly property real reachY: Math.max(hub * 1.6, (rows - 1) / 2 * step + step * 0.4 + thick * 0.45) + Theme.u * 4
    readonly property real reach: Math.max(reachX, reachY)
    readonly property Item blurItem: null
    // opening: folded down along the body (0) → spread (1), past it on the bounce
    readonly property real spread: Math.max(0, menu.reveal)

    // the palette: pale feathers in any palette (the light surface, or the text's pale on dark
    // ones) and dark ink on them; the accent shades the lower vane, the barbs and the shaft,
    // and lights the one you're on like the ring's
    // the pale plate, its ink, the plate you're on (as much of the accent as still leaves the
    // ink at 4.5:1) and the names' ink, for a palette {dark, face, text, accent, surface} —
    // the self-test reads every heaven palette through it
    function coloursFor(t) {
        const plate = t.dark ? Theme.mix(t.text, t.surface, 0.12) : t.surface;
        const ink = readable(t.dark ? t.face : t.text, plate);
        let hot = Theme.mix(plate, t.accent, 0.05);
        for (const k of [0.42, 0.34, 0.26, 0.18, 0.1]) {
            const c = Theme.mix(plate, t.accent, k);
            if (HellLook.contrast(ink, c) >= 4.5) {
                hot = c;
                break;
            }
        }
        const label = readable(t.text, t.surface);
        return {
            "plate": plate,
            "ink": ink,
            "hot": hot,
            "label": label,
            "pairs": [[ink, plate], [ink, hot], [label, t.surface]]
        };
    }
    readonly property var tone: coloursFor({
        "dark": Theme.dark,
        "face": Theme.face,
        "text": Theme.text,
        "accent": Theme.accent,
        "surface": Theme.menuSurface
    })
    readonly property color plume: tone.plate
    readonly property color ink: tone.ink
    readonly property color plumeHot: tone.hot
    readonly property color labelInk: tone.label
    readonly property color rim: Theme.mix(Theme.accent, ink, 0.55)
    // feathers' colours by part: upper vane, lower vane, barbs, shaft, rim
    readonly property var colours: [plume, Theme.mix(plume, Theme.accent, 0.14), Theme.mix(plume, Theme.accent, 0.32), Theme.mix(plume, Theme.accent, 0.55), rim]
    readonly property var coloursHot: [plumeHot, Theme.mix(plumeHot, Theme.accent, 0.16), Theme.mix(plumeHot, Theme.accent, 0.4), Theme.mix(plumeHot, Theme.accent, 0.6), rim]
    // text on what it stands on, for the self-test (tests/ui): icons on the feathers, the
    // names on their outline
    readonly property var pairs: tone.pairs

    // a colour of the palette nudged away from `bg` (darker on a lighter one, lighter on a
    // darker one) until it reads at 4.5:1 — a few palettes (Solarized light) sit just under it
    function readable(fg, bg) {
        const lum = c => 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
        let c = Qt.color(fg);
        const down = lum(c) < lum(Qt.color(bg));
        for (let i = 0; i < 10 && HellLook.contrast(c, bg) < 4.5; i++)
            c = down ? Qt.darker(c, 1.12) : Qt.lighter(c, 1.12);
        return c;
    }
    // row r's tip (where its icon sits), right wing, from the pointer (the left wing is its
    // mirror): the top rows reach out furthest and rise, the lower ones are shorter and hang
    function tipOf(r) {
        const t = rows > 1 ? r / (rows - 1) : 0;
        return Qt.point(shoulderX + shortest + (longest - shortest) * (1 - t * t), (r - (rows - 1) / 2) * step - step * 0.4);
    }
    function angleOf(r) {
        const p = tipOf(r);
        return Math.atan2(p.y - shoulderY, p.x - shoulderX);
    }
    function lengthOf(r) {
        const p = tipOf(r);
        return Math.hypot(p.x - shoulderX, p.y - shoulderY);
    }
    // a feather's half-width along it (0 the quill's end, 1 the tip): bare quill, the vane
    // widening, a long straight run, then a rounded point
    function profile(q) {
        if (q < 0.08)
            return 0.12;
        if (q < 0.3)
            return 0.12 + 0.88 * Math.sin((q - 0.08) / 0.22 * Math.PI / 2);
        if (q < 0.72)
            return 1 - 0.08 * (q - 0.3) / 0.42;
        const t = (q - 0.72) / 0.28;
        return 0.92 * Math.sqrt(Math.max(0, 1 - t * t)) * (1 - 0.3 * t);
    }
    // which part of row r's feather is at (x, y) (from the pointer, right wing): -1 none,
    // 0 upper vane, 1 lower vane, 2 a barb, 3 the shaft; `out` slides it out of the wing
    function featherAt(r, x, y, out) {
        const a = angleOf(r), L = lengthOf(r) + tip * 0.55;
        const dx = x - shoulderX, dy = y - shoulderY;
        const s = dx * Math.cos(a) + dy * Math.sin(a) - out, v = -dx * Math.sin(a) + dy * Math.cos(a);
        const q = s / L;
        if (q < 0 || q > 1)
            return -1;
        // the leading (upper) vane is the narrow one
        const half = (v < 0 ? 0.6 : 1) * thick / 2 * profile(q);
        if (Math.abs(v) > half + px * 0.5)
            return -1;
        if (Math.abs(v) < px * 0.6 && q < 0.9)
            return 3;
        // barbs slant from the shaft towards the tip
        if (((Math.floor((s - Math.abs(v) * 1.5) / px) % 4) + 4) % 4 === 0 && q > 0.12)
            return 2;
        return v < 0 ? 0 : 1;
    }
    // the coverts over where the feathers start: two rows of small round feathers along the
    // wing's leading edge, and a puff at the shoulder. -1 none, else which (0 is on top)
    function covertAt(x, y) {
        const a = angleOf(0), L = lengthOf(0), c = Math.cos(a), sn = Math.sin(a);
        const dx = x - shoulderX, dy = y - shoulderY;
        const s = dx * c + dy * sn, v = -dx * sn + dy * c;
        const rows2 = [[0.02, 0.12, 0.22, 0.32], [0.0, 0.1, 0.2]];
        let id = 0;
        if (dx * dx + (dy - thick * 0.15) * (dy - thick * 0.15) <= Math.pow(thick * 0.45, 2))
            return 0;
        for (let row = 0; row < 2; row++) {
            for (let j = 0; j < rows2[row].length; j++) {
                id++;
                const cs = rows2[row][j] * L, cv = thick * (row ? 0.56 : 0.18), rr = thick * (row ? 0.27 : 0.32 - 0.03 * j);
                const du = (s - cs) / 1.25, dv = v - cv;
                if (du * du + dv * dv <= rr * rr)
                    return id;
            }
        }
        return -1;
    }
    // where entry i's icon is now, in the look's coordinates
    function tipNow(i, out) {
        const r = Math.floor(i / 2), side = i % 2 ? 1 : -1, p = tipOf(r);
        const turn = (1 - spread) * 1.15, grow = 0.55 + 0.45 * Math.min(1, spread);
        const a = angleOf(r);
        const x0 = p.x - shoulderX + Math.cos(a) * (out || 0), y0 = p.y - shoulderY + Math.sin(a) * (out || 0);
        const x = (x0 * Math.cos(turn) - y0 * Math.sin(turn)) * grow, y = (x0 * Math.sin(turn) + y0 * Math.cos(turn)) * grow;
        return Qt.point(menu.cx + side * (shoulderX + x), menu.cy + shoulderY + y);
    }
    // keys: ←/→ cross to the other wing (or open a flyout outwards), ↑/↓ walk along a wing
    function nav(e) {
        const cur = menu.current;
        if (menu.fly && menu.subCurrent >= 0 && (e.key === Qt.Key_Up || e.key === Qt.Key_Down))
            return menu.walk(e);
        if (e.key === Qt.Key_Left || e.key === Qt.Key_Right) {
            if (cur < 0) {
                menu.current = e.key === Qt.Key_Left || n < 2 ? 0 : 1;
                return true;
            }
            const right = cur % 2 === 1;
            if ((e.key === Qt.Key_Right) === right) {
                const en = DeskMenu.entry(menu.slots[cur]);
                if (en && en.flyout)
                    menu.activate(cur);
                return true;
            }
            const j = right ? cur - 1 : cur + 1;
            if (j < n) {
                menu.fly = "";
                menu.current = j;
            }
            return true;
        }
        if (e.key === Qt.Key_Up || e.key === Qt.Key_Down) {
            const j = cur < 0 ? 0 : cur + (e.key === Qt.Key_Down ? 2 : -2);
            if (j >= 0 && j < n) {
                menu.fly = "";
                menu.current = j;
            }
            return true;
        }
        return menu.walk(e);
    }
    anchors.fill: parent

    // the longest name, for the room the labels take
    TextMetrics {
        id: metrics
        font.family: Theme.fontTitle
        font.pixelSize: Theme.sizeTiny
        font.bold: true
        text: {
            let best = "";
            for (const id of look.menu.slots) {
                const e = DeskMenu.entry(id);
                const s = e ? (e.short || e.label) : "";
                if (s.length > best.length)
                    best = s;
            }
            return best;
        }
    }

    // a soft light behind the halo
    Rectangle {
        x: look.menu.cx - width / 2
        y: look.menu.cy + look.shoulderY - height / 2
        width: look.hub * 3.4 * Math.min(1, look.spread)
        height: width
        radius: width / 2
        color: Qt.alpha(Theme.accent, 0.14 * Math.min(1, look.spread))
    }

    // the wings: the right one as drawn, the left one its mirror
    Repeater {
        model: 2
        Item {
            id: wing
            required property int index
            readonly property int side: index        // 0 left, 1 right
            // the right wing's picture, from the pointer: the shoulder to past the furthest tip
            readonly property real x0: Math.floor((look.shoulderX - look.thick * 0.6) / look.px) * look.px
            readonly property real y0: Math.floor((look.tipOf(0).y - look.thick * 0.75) / look.px) * look.px
            readonly property real x1: look.shoulderX + look.longest + look.tip * 0.6 + look.lift + look.px * 2
            readonly property real y1: look.tipOf(Math.max(0, look.rows - 1)).y + look.thick * 0.75
            readonly property int hotRow: look.menu.current >= 0 && look.menu.current % 2 === side ? Math.floor(look.menu.current / 2) : look.menu.flyIndex >= 0 && look.menu.flyIndex % 2 === side ? Math.floor(look.menu.flyIndex / 2) : -1
            anchors.fill: parent
            transform: Scale {
                origin.x: look.menu.cx
                xScale: wing.side ? 1 : -1
            }
            visible: look.n > wing.side
            opacity: Math.min(1, look.spread * 2)

            Item {
                id: art
                x: look.menu.cx + wing.x0
                y: look.menu.cy + wing.y0
                width: wing.x1 - wing.x0
                height: wing.y1 - wing.y0
                // opening turns it out from the shoulder
                transform: [
                    Scale {
                        origin.x: look.shoulderX - wing.x0
                        origin.y: look.shoulderY - wing.y0
                        xScale: 0.55 + 0.45 * Math.min(1, look.spread)
                        yScale: xScale
                    },
                    Rotation {
                        origin.x: look.shoulderX - wing.x0
                        origin.y: look.shoulderY - wing.y0
                        angle: (1 - look.spread) * 66
                    }
                ]

                // every feather of this wing and the coverts, painted once
                Canvas {
                    id: plumage
                    // pixels side by side, no seams between them at a fractional scale
                    antialiasing: false
                    readonly property string shape: [look.rows, look.n, look.px, look.thick, look.longest, wing.side].join(" ") + look.colours.join(" ")
                    anchors.fill: parent
                    onShapeChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const L = look, p = L.px, cols = Math.ceil(width / p), rws = Math.ceil(height / p);
                        // feathers of this wing: rows whose entry is on this side
                        const mine = [];
                        for (let r = 0; r < L.rows; r++)
                            if (r * 2 + wing.side < L.n)
                                mine.push(r);
                        // who is on top at each cell: a covert (0…), a feather (100 + row), none (-1)
                        const owner = new Int16Array(cols * rws).fill(-1), part = new Int8Array(cols * rws);
                        for (let j = 0; j < rws; j++) {
                            for (let i = 0; i < cols; i++) {
                                const x = wing.x0 + (i + 0.5) * p, y = wing.y0 + (j + 0.5) * p;
                                const c = L.covertAt(x, y);
                                if (c >= 0) {
                                    owner[j * cols + i] = c;
                                    part[j * cols + i] = 0;
                                    continue;
                                }
                                for (const r of mine) {
                                    const f = L.featherAt(r, x, y, 0);
                                    if (f >= 0) {
                                        owner[j * cols + i] = 100 + r;
                                        part[j * cols + i] = f;
                                        break;
                                    }
                                }
                            }
                        }
                        // the rim: where the neighbour is empty or lies under it
                        const cells = [[], [], [], [], []];
                        const below = (o, i, j) => {
                            if (i < 0 || j < 0 || i >= cols || j >= rws)
                                return true;
                            const m = owner[j * cols + i];
                            return m < 0 || m > o;
                        };
                        for (let j = 0; j < rws; j++) {
                            for (let i = 0; i < cols; i++) {
                                const o = owner[j * cols + i];
                                if (o < 0)
                                    continue;
                                let kind = part[j * cols + i];
                                if (below(o, i - 1, j) || below(o, i + 1, j) || below(o, i, j - 1) || below(o, i, j + 1))
                                    kind = 4;
                                else if (o < 100 && kind === 0 && (i + j * 2) % 5 === 0)
                                    kind = 1;
                                cells[kind].push(i, j);
                            }
                        }
                        for (let kind = 0; kind < 5; kind++) {
                            ctx.fillStyle = L.colours[kind];
                            const l = cells[kind];
                            for (let m = 0; m < l.length; m += 2)
                                ctx.fillRect(l[m] * p, l[m + 1] * p, p, p);
                        }
                    }
                }
                // the one you're on, lifted out of the wing (its base stays under the coverts)
                Canvas {
                    id: raised
                    // pixels side by side, no seams between them at a fractional scale
                    antialiasing: false
                    readonly property string shape: plumage.shape + " " + wing.hotRow + look.coloursHot.join(" ")
                    anchors.fill: parent
                    visible: wing.hotRow >= 0
                    onShapeChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const L = look, p = L.px, r = wing.hotRow;
                        if (r < 0)
                            return;
                        const cols = Math.ceil(width / p), rws = Math.ceil(height / p);
                        const at = (i, j) => i < 0 || j < 0 || i >= cols || j >= rws ? -1 : L.featherAt(r, wing.x0 + (i + 0.5) * p, wing.y0 + (j + 0.5) * p, L.lift);
                        const cells = [[], [], [], [], []];
                        for (let j = 0; j < rws; j++) {
                            for (let i = 0; i < cols; i++) {
                                const x = wing.x0 + (i + 0.5) * p, y = wing.y0 + (j + 0.5) * p;
                                let kind = at(i, j);
                                if (kind < 0 || L.covertAt(x, y) >= 0)
                                    continue;
                                if (at(i - 1, j) < 0 || at(i + 1, j) < 0 || at(i, j - 1) < 0 || at(i, j + 1) < 0)
                                    kind = 4;
                                cells[kind].push(i, j);
                            }
                        }
                        for (let kind = 0; kind < 5; kind++) {
                            ctx.fillStyle = L.coloursHot[kind];
                            const l = cells[kind];
                            for (let m = 0; m < l.length; m += 2)
                                ctx.fillRect(l[m] * p, l[m + 1] * p, p, p);
                        }
                    }
                }
            }
        }
    }

    // the middle: the logo on a round pale plate, under its halo; closes
    Rectangle {
        id: hubBox
        x: look.menu.cx - width / 2
        y: look.menu.cy + look.shoulderY - height / 2 + look.px * 3
        width: look.hub
        height: width
        radius: width / 2
        scale: Math.min(1, look.spread)
        color: hubMouse.containsMouse ? look.plumeHot : look.plume
        border.width: look.px
        border.color: look.rim
        AngelLogo {
            anchors.centerIn: parent
            emblemOnly: true
            pixel: Math.max(1, Math.round(Theme.u * look.k * 0.75))
        }
        MouseArea {
            id: hubMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                look.menu.current = -1;
                look.menu.fly = "";
            }
            onClicked: look.menu.close()
        }
    }
    // the halo: a flat pixel ellipse floating over the logo
    Canvas {
        id: halo
        // pixels side by side, no seams between them at a fractional scale
        antialiasing: false
        readonly property var colours: [Theme.accent, Qt.lighter(Theme.accent, 1.3), look.rim]
        x: look.menu.cx - width / 2
        y: hubBox.y - height - look.px * 2 - (1 - Math.min(1, look.spread)) * look.hub * 0.4
        width: Math.round(look.hub * 1.5 / look.px) * look.px
        height: Math.round(look.hub * 0.5 / look.px) * look.px
        opacity: Math.min(1, look.spread)
        onColoursChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const p = look.px, cols = Math.floor(width / p), rws = Math.floor(height / p);
            const rx = cols / 2, ry = rws / 2;
            const at = (i, j, s) => {
                const x = (i + 0.5 - rx) / (rx * s), y = (j + 0.5 - ry) / (ry * s);
                return x * x + y * y <= 1;
            };
            // a ring three pixels thick: rim, gold, a lit upper edge
            for (let j = 0; j < rws; j++)
                for (let i = 0; i < cols; i++) {
                    if (!at(i, j, 1) || at(i, j, 0.52))
                        continue;
                    const outer = !at(i, j - 1, 1) || !at(i, j + 1, 1) || !at(i - 1, j, 1) || !at(i + 1, j, 1);
                    const inner = at(i, j - 1, 0.52) || at(i, j + 1, 0.52) || at(i - 1, j, 0.52) || at(i + 1, j, 0.52);
                    ctx.fillStyle = outer || inner ? colours[2] : j < ry ? colours[1] : colours[0];
                    ctx.fillRect(i * p, j * p, p, p);
                }
        }
    }
    // the hovered entry's full name, under the logo
    PxBox {
        visible: !!look.menu.hoveredEntry && look.menu.reveal > 0.6
        x: look.menu.cx - width / 2
        y: hubBox.y + hubBox.height + Theme.u * 3
        width: hoverName.implicitWidth + Theme.u * 8
        height: hoverName.implicitHeight + Theme.u * 4
        color: Qt.alpha(Theme.menuSurface, 0.92)
        PxText {
            id: hoverName
            anchors.centerIn: parent
            kind: "tiny"
            font.bold: true
            color: look.labelInk
            text: look.menu.hoveredEntry ? look.menu.hoveredEntry.label : ""
        }
    }

    // the icons near the tips and the names beside them, over the wings
    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: entry
            menu: look.menu
            readonly property int side: index % 2 ? 1 : -1
            property real out: hot ? look.lift : 0
            Behavior on out {
                NumberAnimation {
                    duration: Motion.ms(90)
                }
            }
            readonly property point at: look.tipNow(index, out)
            x: at.x - width / 2
            y: at.y - height / 2
            width: look.tip
            height: look.tip
            opacity: Math.min(1, look.spread * 1.5)
            PxIcon {
                anchors.centerIn: parent
                // the lower vane is the wide one: the icon sits a little into it
                anchors.verticalCenterOffset: look.px
                name: entry.icon
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.85))
                ink: look.ink
            }
            // a flyout: a notch pointing outwards
            PxText {
                visible: !!(entry.e && entry.e.flyout)
                x: entry.side > 0 ? parent.width - width + look.px * 2 : -look.px * 2
                y: -look.px * 2
                kind: "tiny"
                color: look.rim
                text: entry.side > 0 ? "▸" : "◂"
            }
            PxText {
                visible: look.menu.labels
                x: entry.side > 0 ? parent.width / 2 + look.tip * 0.6 + look.labelGap : parent.width / 2 - look.tip * 0.6 - look.labelGap - width
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: entry.side > 0 ? Text.AlignLeft : Text.AlignRight
                kind: "tiny"
                font.bold: entry.hot
                color: look.labelInk
                style: Text.Outline
                styleColor: Qt.alpha(Theme.menuSurface, 0.9)
                text: entry.label
                // the name is part of the entry
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: look.menu.hoverEntry(entry.index)
                    onClicked: look.menu.activate(entry.index)
                }
            }
        }
    }

    CircleFly {
        hell: false
        menu: look.menu
        reach: look.reachX
        at: {
            if (look.menu.flyIndex < 0)
                return Qt.point(look.menu.cx, look.menu.cy);
            const p = look.tipNow(look.menu.flyIndex, look.lift);
            const s = look.menu.flyIndex % 2 ? 1 : -1;
            return Qt.point(p.x + s * (look.tip * 0.6 + look.labelGap + look.labelW), p.y);
        }
    }
}
