pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of violence: the wood of the suicides. The view is written on a strip
// of linen bandage caught in black thorny branches that grow round its edges; a few drops have
// fallen on it from above. Break no branches.
HellDress {
    id: dress

    paper: "#e3d8c6"
    ink: "#2b1313"
    redInk: "#8f1119"
    title: I18n.t("Не ломай ветвей", "Break no branches")
    titleColor: "#d8b0a8"
    closer: "#4a1a1c"
    closerInk: "#e3d8c6"
    pageX: Theme.u * 14
    pageRight: Theme.u * 14
    pageTop: headHeight + Theme.u * 6
    pageBottom: Theme.u * 14

    // the dark of the wood
    Rectangle {
        anchors.fill: parent
        color: "#3a2220"
        border.width: Math.max(2, Theme.u)
        border.color: "#0c0606"
    }
    // the branches round the bandage: crooked, thorned, over its edge
    Canvas {
        z: 2
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const u = Theme.u;
            const x0 = dress.pageX - u * 3, y0 = dress.pageTop - u * 3;
            const x1 = width - dress.pageRight + u * 3, y1 = height - dress.pageBottom + u * 3;
            ctx.fillStyle = "#0a0404";
            // a branch: a crooked line of blocks, a thorn every so often
            function branch(ax, ay, bx, by, seed) {
                const len = Math.hypot(bx - ax, by - ay), n = Math.floor(len / (u * 2));
                const nx = -(by - ay) / len, ny = (bx - ax) / len;
                for (let i = 0; i <= n; i++) {
                    const t = i / n, wob = Math.round(Math.sin(i * 0.7 + seed) * 1.4) * u;
                    const x = ax + (bx - ax) * t + nx * wob, y = ay + (by - ay) * t + ny * wob;
                    ctx.fillRect(Math.round(x / u) * u - u, Math.round(y / u) * u - u, u * 3, u * 3);
                    if ((i + seed) % 5 === 0) {
                        const s = (i % 2 ? 1 : -1);
                        for (let k = 1; k <= 4; k++)
                            ctx.fillRect(Math.round((x + nx * s * k * u * 1.2) / u) * u, Math.round((y + ny * s * k * u * 1.2) / u) * u, u, u);
                    }
                }
            }
            branch(x0 - u * 6, y0, x1 + u * 4, y0 + u * 2, 1);
            branch(x0, y1, x1 + u * 6, y1 - u * 2, 3);
            branch(x0, y0 - u * 4, x0 + u * 2, y1 + u * 6, 5);
            branch(x1, y0 - u * 6, x1 - u * 2, y1 + u * 2, 2);
        }
    }
    // drops fallen on the bandage's lower edge
    Repeater {
        model: 3
        Rectangle {
            required property int index
            z: 2
            x: dress.pageX + [0.2, 0.55, 0.83][index] * (dress.width - dress.pageX - dress.pageRight)
            y: dress.height - dress.pageBottom - height - Theme.u * [2, 5, 3][index]
            width: Theme.u * 2
            height: Theme.u * 3
            radius: Theme.u
            color: Qt.alpha(dress.redInk, 0.75)
        }
    }
}
