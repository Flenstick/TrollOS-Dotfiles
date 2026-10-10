import QtQuick
import qs.config
import qs.widgets

// Анимация отправки: файлик летит дугой в телефон (за ним сердечки), телефон
// его «глотает»; дошло — салют из сердечек и галочка, не дошло — телефон
// трясётся и роняет разбитое сердце. kdeconnect отвечает быстрее, чем летит
// файлик, поэтому итог показываем, когда он долетел (shownState).
Item {
    id: fx

    property var phone
    property Item target                 // иконка телефона
    property Item source                 // откуда летит, если не задано fromPoint
    property var fromPoint: null         // точка в координатах fx (куда бросили файл)
    property string shownState: "idle"   // idle | sending | done | error
    property string pending: ""
    readonly property int u: Theme.u

    function center(item) {
        return item ? item.mapToItem(fx, item.width / 2, item.height / 2) : Qt.point(width / 2, height / 2);
    }

    Connections {
        target: fx.phone
        function onStateChanged() {
            fx.react(fx.phone.state);
        }
    }
    function react(s) {
        if (s === "sending") {
            shownState = "sending";
            pending = "";
            if (!flight.running)
                launch();
        } else if (s === "done" || s === "error") {
            if (flight.running)
                pending = s;
            else
                finish(s);
        } else if (!flight.running && pending === "") {
            shownState = "idle";
            fromPoint = null;
        }
    }
    function launch() {
        const a = fromPoint ? fromPoint : source ? center(source) : Qt.point(width - u * 16, u * 6);
        const b = center(target);
        doc.sx = a.x;
        doc.sy = a.y;
        doc.tx = b.x;
        doc.ty = b.y;
        doc.popped = 0;
        doc.t = 0;
        flight.restart();
    }
    function landed() {
        gulp.restart();
        if (pending !== "") {
            const s = pending;
            pending = "";
            finish(s);
        } else if (phone.state === "sending")
            launch();
        else
            finish(phone.state === "error" ? "error" : "done");
    }
    function finish(s) {
        shownState = s;
        const p = center(target);
        if (s === "done") {
            hearts.burst(p.x, p.y - u * 4, 16, u * 7);
            jump.restart();
            check.pop();
        } else {
            hearts.drop(p.x, p.y);
            shake.restart();
        }
    }

    // ---- летящий файлик ----
    PxIcon {
        id: doc
        property real sx: 0
        property real sy: 0
        property real tx: 0
        property real ty: 0
        property real t: 0
        property int popped: 0
        readonly property real arc: Math.max(fx.u * 14, Math.abs(tx - sx) * 0.35)
        name: "document"
        pixel: fx.u * 2
        visible: flight.running
        x: sx + (tx - sx) * t - width / 2
        y: sy + (ty - sy) * t - Math.sin(Math.PI * t) * arc - height / 2
        scale: 1.15 - 0.75 * t
        rotation: (1 - t) * -30 + Math.sin(t * Math.PI * 3) * 8
        opacity: t < 0.85 ? 1 : (1 - t) / 0.15
        z: 2
        onTChanged: {
            // сердечки-следы
            if (popped < 3 && t > 0.2 + popped * 0.22) {
                popped++;
                hearts.pop(x + width / 2, y + height / 2);
            }
        }
    }
    NumberAnimation {
        id: flight
        target: doc
        property: "t"
        from: 0
        to: 1
        duration: 640
        easing.type: Easing.InOutQuad
        onFinished: fx.landed()
    }

    // ---- телефон: глотает, прыгает, трясётся ----
    SequentialAnimation {
        id: gulp
        NumberAnimation {
            target: fx.target
            property: "scale"
            to: 0.8
            duration: 70
        }
        NumberAnimation {
            target: fx.target
            property: "scale"
            to: 1.12
            duration: 110
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: fx.target
            property: "scale"
            to: 1
            duration: 120
        }
    }
    SequentialAnimation {
        id: jump
        PauseAnimation {
            duration: 300
        }
        NumberAnimation {
            target: fx.target
            property: "scale"
            to: 1.35
            duration: 160
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: fx.target
            property: "scale"
            to: 1
            duration: 260
            easing.type: Easing.OutBounce
        }
    }
    SequentialAnimation {
        id: shake
        PauseAnimation {
            duration: 300
        }
        NumberAnimation {
            target: fx.target
            property: "rotation"
            to: -14
            duration: 50
        }
        NumberAnimation {
            target: fx.target
            property: "rotation"
            to: 14
            duration: 80
        }
        NumberAnimation {
            target: fx.target
            property: "rotation"
            to: -9
            duration: 80
        }
        NumberAnimation {
            target: fx.target
            property: "rotation"
            to: 9
            duration: 80
        }
        NumberAnimation {
            target: fx.target
            property: "rotation"
            to: 0
            duration: 60
        }
    }

    // ---- галочка над телефоном ----
    PxIcon {
        id: check
        name: "check"
        pixel: fx.u * 2
        fill: Theme.ok
        visible: opacity > 0
        opacity: 0
        z: 3
        property real endY: 0
        function pop() {
            const p = fx.center(fx.target);
            x = p.x - width / 2;
            y = p.y - height / 2 - (fx.target ? fx.target.height / 2 : 0) - fx.u * 6;
            endY = y - fx.u * 8;
            checkAnim.restart();
        }
        SequentialAnimation {
            id: checkAnim
            PauseAnimation {
                duration: 300
            }
            ParallelAnimation {
                NumberAnimation {
                    target: check
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 120
                }
                NumberAnimation {
                    target: check
                    property: "scale"
                    from: 0.2
                    to: 1
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.5
                }
            }
            PauseAnimation {
                duration: 1100
            }
            ParallelAnimation {
                NumberAnimation {
                    target: check
                    property: "opacity"
                    to: 0
                    duration: 300
                }
                NumberAnimation {
                    target: check
                    property: "y"
                    to: check.endY
                    duration: 300
                }
            }
        }
    }

    HeartBurst {
        id: hearts
        anchors.fill: parent
        z: 4
    }
}
