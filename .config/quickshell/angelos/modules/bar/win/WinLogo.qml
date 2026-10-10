import QtQuick
import qs.config
import qs.services

// The four-pane Windows 11 logo with its blue sweep (the angelOS accent when chosen).
Canvas {
    id: root
    property int size: 24
    readonly property color c1: Config.win.accent === "theme" ? Qt.lighter(Theme.accent, 1.35) : "#4dc4ff"
    readonly property color c2: Config.win.accent === "theme" ? Theme.accent : "#0a6ed1"
    width: size
    height: size
    onC1Changed: requestPaint()
    onC2Changed: requestPaint()
    onSizeChanged: requestPaint()
    onPaint: {
        const g = getContext("2d");
        g.reset();
        const grad = g.createLinearGradient(0, 0, size, size);
        grad.addColorStop(0, c1);
        grad.addColorStop(1, c2);
        g.fillStyle = grad;
        const gap = Math.max(1, Math.round(size / 22));
        const s = (size - gap) / 2;
        g.fillRect(0, 0, s, s);
        g.fillRect(s + gap, 0, s, s);
        g.fillRect(0, s + gap, s, s);
        g.fillRect(s + gap, s + gap, s, s);
    }
}
