pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Windows 11 Alt+Tab (bar.style "windows", win.altTab): niri's Alt+Tab bind calls
// `qs ipc call alttab next|prev` (cfg/win-alttab.kdl, written by WinExtras); the
// switcher closes and switches when Alt is let go (evdev via MetaTap, or the key
// release here). Windows in most-recently-used order; pictures are cut from a
// screen capture taken as it opens (windows on screen) and remembered for later.
Scope {
    id: root

    property bool open: false
    // the layer is mapped only after a short hold and kept at least 250 ms: mapping and
    // unmapping a surface within a few ms crashed Qt Wayland (handleScreensChanged)
    property bool shown: false
    readonly property string screenName: screen ? screen.name : ""
    onOpenChanged: {
        if (open) {
            hideTimer.stop();
            if (!shown)
                showDelay.restart();
        } else {
            showDelay.stop();
            if (shown)
                hideTimer.restart();
        }
    }
    Timer {
        id: showDelay
        interval: 90
        onTriggered: if (root.open) {
            root.shown = true;
            minShown.restart();
        }
    }
    Timer {
        id: minShown
        interval: 250
    }
    Timer {
        id: hideTimer
        interval: minShown.running ? 250 : 120
        onTriggered: if (!root.open)
            root.shown = false
    }
    property int index: 0
    property var list: []
    property var pics: ({})            // window id -> {file, rect} of its last picture
    property int shotN: 0
    property var screen: Shell.focusedScreen

    IpcHandler {
        target: "alttab"
        function next(): void {
            root.step(1);
        }
        function prev(): void {
            root.step(-1);
        }
        function close(): void {
            root.cancel();
        }
        // open without waiting for Alt (screenshots, testing); Esc / `alttab close` hide it
        function test(): void {
            root.testing = true;
            root.list = Niri.windows.slice().sort((a, b) => root.ts(b) - root.ts(a));
            root.index = root.list.length > 1 ? 1 : 0;
            root.screen = Shell.focusedScreen;
            root.open = root.list.length > 0;
        }
    }

    function ts(w) {
        return w.focus_timestamp ? w.focus_timestamp.secs + w.focus_timestamp.nanos / 1e9 : 0;
    }
    function step(d) {
        if (!open) {
            list = Niri.windows.slice().sort((a, b) => ts(b) - ts(a));
            if (!list.length)
                return;
            index = list.length > 1 ? (d > 0 ? 1 : list.length - 1) : 0;
            // a quick Alt+Tab (Alt already up): switch at once, like Windows
            if (MetaTap.status === "ready" && !MetaTap.altDown) {
                commit();
                return;
            }
            screen = Shell.focusedScreen;
            open = true;
            return;
        }
        const n = list.length;
        index = ((index + d) % n + n) % n;
    }
    function commit() {
        const w = list[index];
        open = false;
        testing = false;
        if (w)
            Niri.focusWindow(w.id);
    }
    function cancel() {
        open = false;
        testing = false;
    }
    // safety net: never stay open (with the keyboard grabbed) once Alt is up
    Timer {
        interval: 80
        repeat: true
        running: root.open && !root.testing && MetaTap.status === "ready"
        onTriggered: if (!MetaTap.altDown)
            root.commit()
    }
    property bool testing: false
    Connections {
        target: MetaTap
        function onAltReleased() {
            if (root.open)
                root.commit();
        }
    }
    // the list follows windows closing while it is open
    Connections {
        target: Niri
        function onWindowsChanged() {
            if (!root.open)
                return;
            const ids = Niri.windows.map(w => w.id);
            const l = root.list.filter(w => ids.includes(w.id));
            if (l.length !== root.list.length) {
                root.list = l;
                root.index = Math.min(root.index, l.length - 1);
                if (!l.length)
                    root.open = false;
            }
        }
    }

    function cardW(w) {
        const size = w.layout && w.layout.window_size ? w.layout.window_size : [16, 10];
        const aspect = Math.max(0.5, Math.min(2.4, size[0] / Math.max(1, size[1])));
        return Math.round(Math.max(150, Math.min(300, 148 * aspect))) + 16;
    }
    function rectsOn(scr) {
        return WinGeom.rectsOn(scr, true);
    }

    Variants {
        model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        visible: root.shown && root.screenName === modelData.name
        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-alttab"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open && visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None


        BackgroundEffect.blurRegion: Config.appearance.blur && root.open ? blurRegion : null
        Region {
            id: blurRegion
            x: panel.x
            y: panel.y
            width: panel.width
            height: panel.height
            radius: 8
        }

        // pictures: ONE grim shot of the screen (scaled to 35 %) as the switcher opens,
        // before its layer maps; each card shows its window's part of it (sourceClipRect).
        // Shots rotate through 8 files, so a window keeps its last picture for a while.
        // (No ScreencopyView / grabToImage: with them the shell crashed in Qt Wayland.)
        readonly property real k: 0.35
        Process {
            id: grab
            property string file: ""
            property var pending: ({})
            command: ["grim", "-l", "1", "-s", String(win.k), "-o", win.modelData.name, file]
            onExited: code => {
                if (code !== 0)
                    return;
                const p = Object.assign({}, root.pics);
                for (const id in pending)
                    p[id] = {
                        "file": "file://" + file,
                        "rect": pending[id]
                    };
                root.pics = p;
            }
        }
        function shoot() {
            if (grab.running)
                return;
            const rects = root.rectsOn(win.modelData);
            const pend = {};
            for (const id in rects) {
                const q = rects[id];
                pend[id] = Qt.rect(q.x * win.k, q.y * win.k, q.width * win.k, q.height * win.k);
            }
            if (!Object.keys(pend).length)
                return;
            root.shotN = (root.shotN + 1) % 8;
            grab.pending = pend;
            grab.file = Quickshell.env("XDG_RUNTIME_DIR") + "/angelos-alttab-" + root.shotN + ".png";
            grab.running = true;
        }
        Connections {
            target: root
            function onOpenChanged() {
                if (root.open && root.screenName === win.modelData.name)
                    win.shoot();
            }
        }

        // input only while open (the layer lingers a moment after, it must not eat clicks)
        Item {
            id: inputArea
            anchors.fill: parent
        }
        mask: Region {
            item: root.open ? inputArea : null
        }

        // a click outside closes it
        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.cancel()
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape)
                    root.cancel();
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                    root.commit();
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))
                    root.step(1);
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab || e.key === Qt.Key_Tab)
                    root.step(-1);
                else if (e.key === Qt.Key_Delete && root.list[root.index])
                    Niri.closeWindow(root.list[root.index].id);
                e.accepted = true;
            }
            Keys.onReleased: e => {
                if ((e.key === Qt.Key_Alt || e.key === Qt.Key_AltGr) && root.open)
                    root.commit();
            }
        }
        onVisibleChanged: if (visible)
            Qt.callLater(() => keys.forceActiveFocus())

        RectangularShadow {
            anchors.fill: panel
            radius: 8
            blur: 40
            offset.y: 12
            color: WinStyle.shadow
            opacity: panel.opacity
        }
        Rectangle {
            id: panel
            readonly property int maxW: Math.round(win.width * 0.92)
            // like Windows: everything in one row, cards shrink (down to 60 %) before wrapping
            readonly property int n: root.list.length
            readonly property real fixedW: 16 * n + 8 * Math.max(0, n - 1)       // card padding + gaps don't shrink
            readonly property real natural: Math.max(1, flow.implicitW - fixedW)
            readonly property real fit: Math.max(0.6, Math.min(1, (maxW - 32 - fixedW) / natural))
            width: Math.min(maxW, Math.ceil(natural * fit + fixedW) + 32 + 2)
            height: flow.height + 32
            anchors.centerIn: parent
            radius: 8
            color: WinStyle.dark ? Qt.rgba(0.16, 0.16, 0.16, 0.82) : Qt.rgba(0.95, 0.95, 0.95, 0.82)
            border.width: 1
            border.color: WinStyle.flyoutLine
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.97
            Behavior on opacity {
                NumberAnimation {
                    duration: WinStyle.fast
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }

            Flow {
                id: flow
                x: 16
                y: 16
                width: panel.width - 32
                spacing: 8
                // the row's natural width from the windows themselves (cards size from their aspect)
                readonly property real implicitW: root.list.reduce((sum, w, i) => sum + root.cardW(w) + (i ? 8 : 0), 0)

                Repeater {
                    id: rep
                    model: root.list
                    Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property bool sel: root.index === index
                        readonly property int thumbH: Math.round(148 * panel.fit)
                        width: Math.round((root.cardW(modelData) - 16) * panel.fit) + 16
                        height: thumbH + 48

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: cm.containsMouse && !card.sel ? WinStyle.subtleHover : "transparent"
                            border.width: card.sel ? 3 : 0
                            border.color: WinStyle.dark ? "#ffffff" : "#1b1b1b"
                        }
                        Row {
                            x: 10
                            y: 10
                            spacing: 8
                            width: parent.width - 20 - (closeBtn.visible ? 26 : 0)
                            AppIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                appId: card.modelData.app_id || ""
                                size: 16
                            }
                            WinText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 24
                                text: card.modelData.title || card.modelData.app_id || ""
                                font.pixelSize: 12
                            }
                        }
                        Item {
                            id: pic
                            x: 8
                            y: 38
                            width: parent.width - 16
                            height: card.thumbH
                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: WinStyle.card
                                clip: true
                                Image {
                                    id: shot
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    readonly property var shotInfo: root.pics[card.modelData.id] || null
                                    source: shotInfo ? shotInfo.file : ""
                                    sourceClipRect: shotInfo ? shotInfo.rect : Qt.rect(0, 0, 0, 0)
                                    visible: status === Image.Ready
                                }
                                AppIcon {
                                    visible: !shot.visible
                                    anchors.centerIn: parent
                                    appId: card.modelData.app_id || ""
                                    size: 48
                                }
                            }
                        }
                        MouseArea {
                            id: cm
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.index = card.index;
                                root.commit();
                            }
                        }
                        // × on hover, like Windows
                        Rectangle {
                            id: closeBtn
                            visible: cm.containsMouse || xa.containsMouse
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            y: 8
                            width: 22
                            height: 22
                            radius: 4
                            color: xa.containsMouse ? "#c42b1c" : "transparent"
                            WinIcon {
                                anchors.centerIn: parent
                                name: "dismiss-regular"
                                size: 12
                            }
                            MouseArea {
                                id: xa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Niri.closeWindow(card.modelData.id)
                            }
                        }
                    }
                }
            }
        }

        RightClickGuard {}
    }
    }
}
