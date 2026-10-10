pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of treachery: a sheet frozen into the ice of Cocytus. Deep blue ice
// round it, its edge jagged where it froze, frost flowers grown over the corners. Nothing
// moves.
HellDress {
    id: dress

    paper: "#dde9f0"
    ink: "#0f2436"
    redInk: "#255d8a"
    title: I18n.t("Коцит", "Cocytus")
    titleColor: "#b8d4e4"
    closer: "#1d3448"
    closerInk: "#dde9f0"
    pageX: Theme.u * 14
    pageRight: Theme.u * 14
    pageTop: headHeight + Theme.u * 6
    pageBottom: Theme.u * 14

    // the ice
    Rectangle {
        anchors.fill: parent
        color: "#0f1d2a"
        border.width: Math.max(2, Theme.u)
        border.color: "#07101a"
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.u * 3
            color: "transparent"
            border.width: Math.max(1, Theme.u / 2)
            border.color: Qt.alpha("#b8d4e4", 0.18)
        }
    }
    // the edge where the sheet froze: a saw of ice round the page
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const u = Theme.u;
            const x0 = dress.pageX, y0 = dress.pageTop, x1 = width - dress.pageRight, y1 = height - dress.pageBottom;
            ctx.globalAlpha = 0.55;
            ctx.fillStyle = "#b8d4e4";
            for (let x = x0; x < x1; x += u * 4) {
                const h = ((x / u) * 7 % 5 + 1) * u;
                ctx.fillRect(x, y0 - h, u * 2, h);
                ctx.fillRect(x + u, y1, u * 2, h);
            }
            for (let y = y0; y < y1; y += u * 4) {
                const w = ((y / u) * 5 % 4 + 1) * u;
                ctx.fillRect(x0 - w, y, w, u * 2);
                ctx.fillRect(x1, y + u, w, u * 2);
            }
        }
    }
    // frost flowers over the corners
    Repeater {
        model: 4
        PxIcon {
            required property int index
            z: 2
            bitmap: ["...w...", "w..w..w", ".w.w.w.", "..www..", "wwwwwww", "..www..", ".w.w.w.", "w..w..w", "...w..."]
            pixel: Math.max(1, Theme.u)
            light: "#e8f2f8"
            opacity: 0.85
            x: (index % 2 ? dress.width - dress.pageRight : dress.pageX) - width / 2
            y: (index >= 2 ? dress.height - dress.pageBottom : dress.pageTop) - height / 2
        }
    }
}
