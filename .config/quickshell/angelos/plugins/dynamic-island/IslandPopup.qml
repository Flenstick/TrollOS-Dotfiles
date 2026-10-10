pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Остров на одном экране. Окно на весь экран (оверлей), но ввод ловит только
// коробка острова — и, пока он открыт кликом, прозрачная «ловушка» вокруг,
// чтобы клик мимо закрывал его. Коробка вырастает из строки текста на панели.
PanelWindow {
    id: win

    required property var modelData
    property var host
    readonly property bool mine: !!host && host.open && host.screenName === modelData.name
    readonly property bool dragMode: !!host && host.dragMode
    readonly property var phone: host ? host.phone : null
    readonly property int u: Theme.u

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "angelos-island"
    WlrLayershell.keyboardFocus: mine && !dragMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // окно создаётся заранее, пока мышь над строкой на панели: первый кадр
    // нового слоя рисуется ~60 мс, и без этого начало анимации проглатывается
    readonly property bool warm: !!host && host.warmScreen === modelData.name
    readonly property bool shown: mine || p > 0.002
    visible: shown || warm

    mask: Region {
        item: win.shown ? box : nothing
        Region {
            item: catcher
        }
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: win.shown ? box : nothing
    }

    // ---- геометрия: откуда растём (строка на панели) и куда ----
    property real p: 0
    property real fx: 0
    property real fy: 0
    property real fw: 0
    property real fh: 0
    property real barTop: 0
    property real barBottom: 0
    property bool fromBottom: true

    function captureFrom() {
        const sw = modelData.width, sh = modelData.height;
        const it = host.anchorItem;
        const w = it && it.QsWindow ? it.QsWindow.window : null;
        if (w && it.visible) {
            const a = w.anchors, m = w.margins;
            const wx = a.left ? m.left : a.right ? sw - w.width - m.right : (sw - w.width) / 2;
            const wy = a.top ? m.top : a.bottom ? sh - w.height - m.bottom : (sh - w.height) / 2;
            const pt = it.mapToItem(null, 0, 0);
            fx = wx + pt.x;
            fy = wy + pt.y;
            fw = it.width;
            fh = it.height;
            barTop = wy;
            barBottom = wy + w.height;
        } else {
            // открыт с клавиши: растём из середины нижней панели
            fw = u * 60;
            fh = u * 13;
            fx = (sw - fw) / 2;
            fy = sh - u * 20 + (u * 20 - fh) / 2;
            barTop = sh - u * 20;
            barBottom = sh;
        }
        fromBottom = fy + fh / 2 > sh / 2;
    }

    readonly property real tw: dragMode ? u * 160 : u * 200
    readonly property real th: (dragMode ? dropView.implicitHeight : fullView.implicitHeight) + box.inset * 2
    property real atw: tw
    property real ath: th
    Behavior on atw {
        enabled: win.p > 0.99
        NumberAnimation {
            duration: Theme.normal
            easing.type: Easing.OutCubic
        }
    }
    Behavior on ath {
        enabled: win.p > 0.99
        NumberAnimation {
            duration: Theme.normal
            easing.type: Easing.OutCubic
        }
    }
    readonly property real tx: Math.max(u * 4, Math.min(modelData.width - atw - u * 4, fx + fw / 2 - atw / 2))
    readonly property real ty: fromBottom ? barTop - ath - u * 3 : barBottom + u * 3

    Item {
        id: nothing
    }
    // окно ещё не было на экране — запустить анимацию со второго кадра
    property bool waitFrame: false
    FrameAnimation {
        running: win.waitFrame
        onTriggered: {
            if (currentFrame < 2)
                return;
            win.waitFrame = false;
            openAnim.restart();
        }
    }
    onMineChanged: {
        if (mine) {
            const cold = !warm && p <= 0.002;
            captureFrom();
            closeAnim.stop();
            if (cold)
                waitFrame = true;
            else
                openAnim.restart();
        } else {
            waitFrame = false;
            openAnim.stop();
            closeAnim.restart();
        }
    }
    NumberAnimation {
        id: openAnim
        target: win
        property: "p"
        to: 1
        duration: 460
        easing.type: Easing.OutBack
        easing.overshoot: 1.25
    }
    NumberAnimation {
        id: closeAnim
        target: win
        property: "p"
        to: 0
        duration: 230
        easing.type: Easing.InCubic
    }

    // клик мимо острова — закрыть
    MouseArea {
        id: catcher
        width: win.mine && !win.dragMode ? win.width : 0
        height: win.mine && !win.dragMode ? win.height : 0
        acceptedButtons: Qt.AllButtons
        onPressed: win.host.close()
    }

    PxBox {
        id: box
        visible: win.shown
        readonly property real lerpW: win.fw + (win.atw - win.fw) * win.p
        readonly property real lerpH: win.fh + (win.ath - win.fh) * win.p
        x: Math.round(win.fx + (win.tx - win.fx) * win.p)
        y: Math.round(win.fy + (win.ty - win.fy) * win.p)
        width: Math.max(u * 4, Math.round(lerpW))
        height: Math.max(u * 4, Math.round(lerpH))
        color: Theme.panel
        shadow: win.p > 0.6 && Config.appearance.shadows
        focus: win.mine
        Keys.onEscapePressed: win.host.close()

        // пока остров маленький — в нём та же строка, что и на панели
        PxText {
            anchors.centerIn: parent
            width: parent.width - win.u * 6
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: win.host && win.host.anchorItem && win.host.anchorItem.line !== undefined ? win.host.anchorItem.line : Lyrics.current !== "" ? Lyrics.current : Lyrics.title
            opacity: Math.max(0, 1 - win.p * 2.5)
            visible: opacity > 0
        }

        Item {
            id: clipper
            anchors.fill: parent
            clip: true
            opacity: Math.max(0, Math.min(1, (win.p - 0.45) / 0.4))

            FullView {
                id: fullView
                width: win.u * 200 - box.inset * 2
                visible: !win.dragMode
                host: win.host
                active: win.mine
                fxState: sendFx.shownState
            }
            DropView {
                id: dropView
                width: win.u * 160 - box.inset * 2
                visible: win.dragMode
                phone: win.phone
                hovering: dropZone.containsDrag
                st: sendFx.shownState
            }
        }

        Connections {
            target: win.host
            function onDroppedFrom(where, x, y) {
                // с панели файлик взлетает снизу, с острова — с места, где отпустили
                sendFx.fromPoint = where === "bar" ? Qt.point(sendFx.width / 2, sendFx.height + win.u * 14) : Qt.point(x, y);
            }
        }
        SendFx {
            id: sendFx
            anchors.fill: clipper
            opacity: clipper.opacity
            phone: win.phone
            target: win.dragMode ? dropView.phoneItem : fullView.phoneItem
            source: win.dragMode ? null : fullView.sendSource
        }

        DropArea {
            id: dropZone
            anchors.fill: parent
            enabled: win.mine
            onEntered: d => {
                win.host.dragEnter(null, win.modelData.name);
                d.accept(Qt.CopyAction);
            }
            onExited: win.host.dragLeft()
            onDropped: d => {
                const p = dropZone.mapToItem(sendFx, d.x, d.y);
                if (win.host.handleDrop(d, "island", p.x, p.y))
                    d.accept(Qt.CopyAction);
                else {
                    d.accepted = false;
                    win.host.dragLeft();
                }
            }
        }
    }
}
