pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// The lens at the pointer (services/Lens): an overlay over one screen that follows
// the mouse and magnifies the picture of the screen under it (shaders/lens.frag).
// It holds the mouse and the keys while it is open — the rest of the screen stays
// live under it. Wheel: zoom; Shift+wheel: size; left click / R: a new picture;
// right click / Esc / Mod+Alt+0: close.
Scope {
    id: root

    LazyLoader {
        active: Lens.open && !!Shell.screenByName(Lens.screenName)

        PanelWindow {
            id: win
            screen: Shell.screenByName(Lens.screenName)
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            // takes input: the snapshot lens: a click puts it away
            WlrLayershell.namespace: "angelos-lens"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // where the pointer is: the last spot angelOS knows until it moves here
            property real px: Pointer.screen === Lens.screenName ? Pointer.x : width / 2
            property real py: Pointer.screen === Lens.screenName ? Pointer.y : height / 2
            readonly property real radius: Lens.size / 2

            Image {
                id: snap
                visible: false
                source: Lens.snapUrl
                cache: false
                smooth: !Config.lens.crisp
            }
            ShaderEffect {
                id: lens
                anchors.fill: parent
                visible: !Lens.hidden && snap.status === Image.Ready
                property var source: snap
                property point center: Qt.point(win.px, win.py)
                property point spot: Qt.point(win.px, win.py)
                property size itemSize: Qt.size(width, height)
                property size texSize: Qt.size(Math.max(1, snap.implicitWidth), Math.max(1, snap.implicitHeight))
                property real radius: win.radius
                property real zoom: Lens.zoom
                property real shape: Config.lens.shape === "square" ? 1 : 0
                property real crisp: Config.lens.crisp ? 1 : 0
                property real rim: Math.max(2, Theme.u * 1.5)
                property color rimColor: Theme.accent
                property color edgeColor: Theme.edge
                fragmentShader: Qt.resolvedUrl("../../shaders/lens.frag.qsb")
            }
            // a small pixel cross where the pointer is (the real one is hidden)
            Item {
                visible: lens.visible
                x: Math.round(win.px)
                y: Math.round(win.py)
                readonly property int arm: Theme.u * 4
                readonly property int t: Math.max(1, Theme.u / 2)
                Rectangle {
                    x: -parent.arm
                    y: -parent.t
                    width: parent.arm * 2 + parent.t
                    height: parent.t * 3
                    color: Theme.edge
                }
                Rectangle {
                    x: -parent.t
                    y: -parent.arm
                    width: parent.t * 3
                    height: parent.arm * 2 + parent.t
                    color: Theme.edge
                }
                Rectangle {
                    x: -parent.arm + parent.t
                    y: 0
                    width: parent.arm * 2 - parent.t
                    height: parent.t
                    color: "#ffffff"
                }
                Rectangle {
                    x: 0
                    y: -parent.arm + parent.t
                    width: parent.t
                    height: parent.arm * 2 - parent.t
                    color: "#ffffff"
                }
            }
            // ×2 on the rim
            PxBox {
                visible: lens.visible
                x: Math.round(win.px + win.radius * 0.7)
                y: Math.round(win.py + win.radius * 0.7)
                width: zoomText.implicitWidth + Theme.u * 6
                height: zoomText.implicitHeight + Theme.u * 2
                color: Theme.accent
                PxText {
                    id: zoomText
                    anchors.centerIn: parent
                    kind: "tiny"
                    font.bold: true
                    color: Theme.selectText
                    text: "×" + (Math.round(Lens.zoom * 10) / 10)
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.BlankCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPositionChanged: m => {
                    win.px = m.x;
                    win.py = m.y;
                }
                onPressed: m => {
                    if (m.button === Qt.LeftButton)
                        Lens.refresh();
                    else
                        Lens.close();
                }
                onWheel: w => {
                    const steps = w.angleDelta.y > 0 ? 1 : w.angleDelta.y < 0 ? -1 : 0;
                    if (steps)
                        Lens.wheel(steps, (w.modifiers & Qt.ShiftModifier) !== 0);
                }
            }
            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape || e.key === Qt.Key_Q)
                        Lens.close();
                    else if (e.key === Qt.Key_R || e.key === Qt.Key_Space)
                        Lens.refresh();
                    else if (e.key === Qt.Key_Plus || e.key === Qt.Key_Equal)
                        Lens.cmd("in");
                    else if (e.key === Qt.Key_Minus)
                        Lens.cmd("out");
                    else
                        return;
                    e.accepted = true;
                }
            }
            RightClickGuard {}
        }
    }
}
