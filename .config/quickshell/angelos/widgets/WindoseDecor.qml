import QtQuick
import qs.config

// Quiet pixel webs and little stray stars inside a Windose window. The canvas
// has no pointer handlers, so controls beneath it remain usable.
Item {
    id: root

    property color thread: Theme.windoseLavender
    property color sparkle: Theme.windoseRose

    Canvas {
        id: art
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const px = Math.max(1, Theme.u / 2);
            const reach = Math.min(Theme.u * 37, width * 0.13, height * 0.27);
            if (reach < Theme.u * 12)
                return;

            function web(x, y, sx, sy) {
                ctx.strokeStyle = Theme.hex(root.thread);
                ctx.lineWidth = px;
                ctx.globalAlpha = Theme.dark ? 0.58 : 0.48;
                for (let i = 1; i <= 5; i++) {
                    const end = reach * i / 5;
                    ctx.beginPath();
                    ctx.moveTo(x + sx * end, y);
                    ctx.lineTo(x + sx * end * 0.46, y + sy * end * 0.46);
                    ctx.lineTo(x, y + sy * end);
                    ctx.stroke();
                }
                for (let i = 1; i <= 4; i++) {
                    const arc = reach * i / 4;
                    ctx.beginPath();
                    ctx.moveTo(x + sx * arc, y);
                    ctx.lineTo(x + sx * arc * 0.69, y + sy * arc * 0.25);
                    ctx.lineTo(x + sx * arc * 0.25, y + sy * arc * 0.69);
                    ctx.lineTo(x, y + sy * arc);
                    ctx.stroke();
                }
            }
            web(0, 0, 1, 1);
            web(width, 0, -1, 1);
            web(0, height, 1, -1);
            web(width, height, -1, -1);

            // A tiny spider hanging from the right web, drawn as pixels.
            const spiderX = width - Math.round(reach * 0.35 / px) * px;
            const spiderY = Math.round(reach * 0.82 / px) * px;
            ctx.strokeStyle = Theme.hex(root.thread);
            ctx.globalAlpha = Theme.dark ? 0.6 : 0.5;
            ctx.beginPath();
            ctx.moveTo(spiderX, 0);
            ctx.lineTo(spiderX, spiderY - 4 * px);
            ctx.stroke();
            ctx.fillStyle = Theme.hex(root.sparkle);
            ctx.fillRect(spiderX - 3 * px, spiderY - 3 * px, 6 * px, 6 * px);
            ctx.lineWidth = px;
            for (const side of [-1, 1]) {
                for (let leg = -1; leg <= 1; leg++) {
                    ctx.beginPath();
                    ctx.moveTo(spiderX + side * 2 * px, spiderY + leg * px);
                    ctx.lineTo(spiderX + side * 6 * px, spiderY + (leg - 1) * 2 * px);
                    ctx.stroke();
                }
            }

            ctx.globalAlpha = Theme.dark ? 0.6 : 0.48;
            ctx.fillStyle = Theme.hex(root.sparkle);
            for (const point of [[0.16, 0.09], [0.89, 0.13], [0.11, 0.83], [0.84, 0.89]]) {
                const x = Math.round(width * point[0] / px) * px;
                const y = Math.round(height * point[1] / px) * px;
                ctx.fillRect(x, y - 2 * px, px, 5 * px);
                ctx.fillRect(x - 2 * px, y, 5 * px, px);
            }
            ctx.globalAlpha = 1;
        }
    }

    onThreadChanged: art.requestPaint()
    onSparkleChanged: art.requestPaint()
}
