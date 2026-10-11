import QtQuick
import qs.config
import qs.services
import qs.widgets
import "../../../widgets/Icons.js" as Icons

PxButton {
    id: root
    // screen readers (widgets/A11y.js): what this icon is
    Accessible.name: I18n.t("Уведомления", "Notifications")
    Accessible.description: (Config.notifications.dnd ? I18n.t("не беспокоить; ", "do not disturb; ") : "") + I18n.t("непрочитанных: ", "unread: ") + Notifs.unread

    compact: true
    flat: true
    icon: Config.notifications.dnd ? "bellOff" : "bell"
    text: Notifs.unread > 0 ? String(Notifs.unread) : ""
    onClicked: Config.notifications.dnd = !Config.notifications.dnd

    // «Не беспокоить» анимируется прямо на значке, как в шторке телефона:
    //   вкл   колокол звенит (качается, по бокам волны), потом черта прочерчивается
    //         по пикселю сверху вниз, и значок пружинит
    //   выкл  черта стирается по пикселю, колокол вздрагивает и звенит сильнее
    readonly property bool dnd: Config.notifications.dnd
    property bool ready: false   // конфиг ещё грузится — не играть
    property bool animating: onAnim.running || offAnim.running
    property real slash: 0       // 0..frames.length-1: сколько пикселей черты нарисовано
    property real swing: 0
    property real pop: 1
    property real waves: 0
    property real waveAmp: 0

    // кадры: bell → bellOff, черта по одной клетке от верхнего правого угла
    readonly property var frames: {
        const on = Icons.get("bell"), off = Icons.get("bellOff");
        const cells = [];
        off.forEach((row, y) => [...row].forEach((ch, x) => {
                if (ch === "r")
                    cells.push([y, x]);
            }));
        const out = [on];
        for (let k = 1; k < cells.length; k++) {
            const rows = off.map(r => [...r]);
            for (let i = k; i < cells.length; i++) {
                const [y, x] = cells[i];
                rows[y][x] = (on[y] || "")[x] || ".";
            }
            out.push(rows.map(r => r.join("")));
        }
        out.push(off);
        return out;
    }

    onDndChanged: {
        if (!ready || Skin.ms(100) === 0)
            return;
        onAnim.stop();
        offAnim.stop();
        (dnd ? onAnim : offAnim).restart();
    }
    Timer {
        interval: 2500
        running: true
        onTriggered: root.ready = true
    }

    Binding {
        target: root.iconItem
        property: "bitmap"
        value: Array.from(root.frames[Math.round(root.slash)])
        when: root.animating
    }
    Binding {
        target: root.iconItem
        property: "rotation"
        value: root.swing
    }
    Binding {
        target: root.iconItem
        property: "scale"
        value: root.pop
    }
    Binding {
        target: root.iconItem
        property: "transformOrigin"
        value: Item.Top
    }
    Binding {
        target: root.iconItem
        property: "smooth"
        value: Math.abs(root.swing) > 0.5
    }

    // волны звука по бокам значка
    Repeater {
        model: 4
        PxIcon {
            required property int index
            readonly property bool isRight: index % 2 === 1
            readonly property real t: (((root.waves + (index >> 1) * 0.5) % 1) + 1) % 1
            readonly property Item ic: root.iconItem
            visible: root.waveAmp > 0.01 && ic.visible
            bitmap: isRight ? ["#.", ".#", ".#", ".#", "#."] : [".#", "#.", "#.", "#.", ".#"]
            pixel: Theme.u
            ink: root.barInk ? Theme.hellAccent : Theme.accent
            opacity: root.waveAmp * Math.sin(t * Math.PI)
            x: ic.parent.x + ic.x + (isRight ? ic.width + Theme.u * (1 + t * 3) : -width - Theme.u * (1 + t * 3))
            y: ic.parent.y + ic.y + ic.height * 0.4 - height / 2
        }
    }

    SequentialAnimation {
        id: onAnim
        PropertyAction { target: root; property: "slash"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pop"; from: 1; to: 1.2; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "waveAmp"; from: 0; to: 1; duration: 100 }
            NumberAnimation { target: root; property: "waves"; from: 0; to: 1.5; duration: 560 }
            SequentialAnimation {
                NumberAnimation { target: root; property: "swing"; to: 18; duration: 80; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "swing"; to: -15; duration: 120; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: 10; duration: 110; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: -5; duration: 100; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: 0; duration: 90; easing.type: Easing.OutQuad }
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "slash"; to: root.frames.length - 1; duration: 260 }
            NumberAnimation { target: root; property: "waveAmp"; to: 0; duration: 180 }
        }
        NumberAnimation { target: root; property: "pop"; to: 0.85; duration: 80; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "pop"; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }

    SequentialAnimation {
        id: offAnim
        PropertyAction { target: root; property: "slash"; value: root.frames.length - 1 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "slash"; to: 0; duration: 240 }
            NumberAnimation { target: root; property: "pop"; from: 1; to: 1.25; duration: 240; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "waveAmp"; from: 0; to: 1; duration: 80 }
            NumberAnimation { target: root; property: "waves"; from: 0; to: 2; duration: 680 }
            SequentialAnimation {
                NumberAnimation { target: root; property: "swing"; to: 24; duration: 70; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "swing"; to: -20; duration: 110; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: 15; duration: 105; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: -10; duration: 100; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: 5; duration: 95; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "swing"; to: 0; duration: 90; easing.type: Easing.OutQuad }
            }
            SequentialAnimation {
                PauseAnimation { duration: 120 }
                NumberAnimation { target: root; property: "pop"; to: 1; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 3 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 480 }
                NumberAnimation { target: root; property: "waveAmp"; to: 0; duration: 200 }
            }
        }
    }
}
