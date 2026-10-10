pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets

// Y2K glitter behind the pointer, drawn where angelOS can see it (the bare
// desktop). A small pool of sparkles is reused round-robin; nothing animates
// while the pointer rests.
Item {
    id: root

    property int next: 0
    property point last: Qt.point(-100, -100)
    property double lastAt: 0

    function spawn(x, y) {
        if (Motion.still)
            return;
        const now = Date.now();
        if (now - lastAt < 35 || Math.abs(x - last.x) + Math.abs(y - last.y) < Theme.u * 4)
            return;
        lastAt = now;
        last = Qt.point(x, y);
        const s = pool.itemAt(next);
        next = (next + 1) % pool.count;
        if (s)
            s.burst(x, y);
    }

    Repeater {
        id: pool
        model: 18
        PxIcon {
            id: spark
            required property int index
            name: ["sparkle", "heartSmall", "star"][index % 3]
            pixel: Math.max(1, Math.round(Theme.u / 2)) * (index % 4 === 0 ? 2 : 1)
            fill: [Theme.accent, Theme.accent2, "#ffffff", Theme.accent3][index % 4]
            visible: opacity > 0
            opacity: 0
            function burst(x, y) {
                fly.stop();
                spark.x = x - width / 2 + (Math.random() - 0.5) * Theme.u * 6;
                spark.y = y - height / 2 + (Math.random() - 0.5) * Theme.u * 4;
                fall.from = spark.y;
                fall.to = spark.y + Theme.u * (8 + Math.random() * 10);
                fly.start();
            }
            ParallelAnimation {
                id: fly
                NumberAnimation {
                    id: fall
                    target: spark
                    property: "y"
                    duration: Motion.ms(700)
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: spark
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Motion.ms(700)
                    easing.type: Easing.InQuad
                }
            }
        }
    }
}
