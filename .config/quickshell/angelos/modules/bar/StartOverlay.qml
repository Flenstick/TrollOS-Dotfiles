pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar.win

// Start menu as a layer-shell overlay: opens from the Start button, from a
// Meta tap or over IPC, takes the keyboard and closes on a click outside.
// Three looks (Settings → Bar → Start): classic Win98 list, Windows 11 panel,
// iPhone-like full screen grid. All of them animate through `reveal` (0 → 1).
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property string screenName: modelData.name
        readonly property bool open: Shell.startScreen === screenName
        readonly property string style: ["classic", "win11", "fullscreen", "windows"].includes(Config.bar.startStyle) ? Config.bar.startStyle : "classic"
        readonly property bool full: style === "fullscreen"
        readonly property bool winReal: style === "windows"   // Windows 11 copy: rises from behind the taskbar
        property bool shown: false
        property real reveal: 0
        // a freshly mapped layer shows its first frame ~60 ms late: keep it mapped while the
        // pointer is on Start (Windows copy), and on a cold open start animating on frame 2
        readonly property bool warm: winReal && Shell.startWarm === screenName
        property bool waitFrame: false
        FrameAnimation {
            running: win.waitFrame
            onTriggered: {
                if (currentFrame < 2)
                    return;
                win.waitFrame = false;
                revealAnim.restart();
            }
        }

        screen: modelData
        visible: shown || warm
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-start"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: open ? (Shell.dev ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

        onOpenChanged: {
            if (open) {
                const cold = !visible;
                shown = true;
                if (body.item && body.item.reset)
                    body.item.reset();
                if (body.item)
                    body.item.current = -1;
                revealAnim.to = 1;
                revealAnim.duration = win.full ? 340 : win.winReal ? WinStyle.slow : 230;
                revealAnim.easing.type = win.full ? Easing.OutQuint : win.winReal ? Easing.BezierSpline : Easing.OutCubic;
                revealAnim.easing.bezierCurve = WinStyle.decelerate;
                if (cold && win.winReal)
                    win.waitFrame = true;
                else
                    revealAnim.restart();
                Qt.callLater(() => keys.forceActiveFocus());
            } else if (shown) {
                revealAnim.to = 0;
                revealAnim.duration = win.full ? 200 : win.winReal ? WinStyle.normal : 140;
                revealAnim.easing.type = win.winReal ? Easing.BezierSpline : Easing.InCubic;
                revealAnim.easing.bezierCurve = WinStyle.accelerate;
                revealAnim.restart();
            }
        }
        NumberAnimation {
            id: revealAnim
            target: win
            property: "reveal"
            onFinished: if (!win.open)
                win.shown = false
        }

        // where the Start button of this screen sits (layer shell does not tell
        // us the bar position, so it is derived from the bar window's anchors)
        readonly property rect button: {
            const b = Shell.startButtons[screenName];
            if (!b || !b.item || !b.window)
                return Qt.rect(Theme.u * 2, height - Theme.u * 20, Theme.u * 40, Theme.u * 18);
            const w = b.window, it = b.item;
            const p = it.mapToItem(w.contentItem, 0, 0);
            const bottom = w.anchors && w.anchors.bottom && !w.anchors.top;
            const wy = bottom ? height - w.height - (w.margins ? w.margins.bottom : 0) : (w.margins ? w.margins.top : 0);
            const wx = w.anchors && w.anchors.left && w.anchors.right ? (w.margins ? w.margins.left : 0) : (width - w.width) / 2;
            return Qt.rect(wx + p.x, wy + p.y, it.width, it.height);
        }
        readonly property bool above: button.y > height / 2

        mask: Region {
            item: win.open ? catcher : null
        }
        BackgroundEffect.blurRegion: Config.appearance.blur && win.shown ? blurRegion : null
        // Windows copy: blur only where the rising menu is, cut at the taskbar's top edge
        Region {
            id: blurRegion
            item: win.full ? catcher : body
            intersection: Intersection.Combine
            // explicit window coordinates: a child Region given an item lands shifted
            readonly property var bi: win.winReal && body.item && body.item.blurItem ? body.item.blurItem : null
            Region {
                x: blurRegion.bi ? body.x + blurRegion.bi.x : (win.full ? 0 : body.x)
                y: blurRegion.bi ? body.y + blurRegion.bi.y : (win.full ? 0 : body.y)
                width: blurRegion.bi ? blurRegion.bi.width : (win.full ? win.width : body.width)
                height: blurRegion.bi ? blurRegion.bi.height : (win.full ? win.height : body.height)
                radius: win.winReal ? 8 : 0
                intersection: Intersection.Intersect
            }
        }

        MouseArea {
            id: catcher
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: Shell.closeStart()
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (body.item)
                    body.item.key(e);
            }
        }

        Loader {
            id: body
            // Settings → Bar → Start: auto keeps classic at the button and win11 centred;
            // left / center / right pin either of them there. Fullscreen fills.
            readonly property real restY: win.above ? win.button.y - height - Theme.u * 2 : win.button.y + win.button.height + Theme.u * 2
            readonly property string align: Config.bar.startAlign && Config.bar.startAlign !== "auto" ? Config.bar.startAlign : win.style === "win11" ? "center" : "button"
            readonly property real edge: Theme.u * 4
            // Windows copy: centred (or 12 px from the left) and sitting on the taskbar's top edge
            readonly property real winX: Config.win.align === "left" ? 12 - (item ? item.margin : 0) : Math.round((win.width - width) / 2)
            readonly property real barTop: win.button.y - (Shell.startButtons[win.screenName] ? Math.max(0, (48 - win.button.height) / 2) : 0)
            x: win.winReal ? winX : win.full ? 0 : align === "center" ? Math.round((win.width - width) / 2) : align === "left" ? edge : align === "right" ? win.width - width - edge : Math.max(Theme.u * 2, Math.min(win.width - width - Theme.u * 2, win.button.x))
            y: win.winReal ? barTop - height : win.full ? 0 : restY + (win.style === "win11" ? (win.above ? 1 : -1) * (1 - win.reveal) * Theme.u * 24 : 0)
            opacity: win.full || win.winReal ? 1 : win.reveal
            // classic pops out of its corner, win11 slides
            scale: win.style === "classic" && !win.winReal ? 0.9 + 0.1 * win.reveal : 1
            transformOrigin: align === "right" ? (win.above ? Item.BottomRight : Item.TopRight) : align === "center" ? (win.above ? Item.Bottom : Item.Top) : (win.above ? Item.BottomLeft : Item.TopLeft)
            sourceComponent: win.full ? fullComp : win.winReal ? winComp : win.style === "win11" ? win11Comp : classicComp
            onLoaded: {
                item.closeRequested.connect(Shell.closeStart);
                if (win.open && item.reset)
                    item.reset();
            }
            MouseArea {
                visible: !win.full
                anchors.fill: parent
                anchors.margins: win.winReal && body.item && body.item.margin ? body.item.margin : 0
                anchors.bottomMargin: win.winReal ? 12 : 0
                z: -1
            }
        }
        Component {
            id: classicComp
            StartMenuBody {}
        }
        Component {
            id: winComp
            WinStartMenu {
                reveal: win.reveal
            }
        }
        Component {
            id: win11Comp
            StartWin11 {}
        }
        Component {
            id: fullComp
            StartFullscreen {
                reveal: win.reveal
                width: win.width
                height: win.height
            }
        }

        RightClickGuard {}
    }
}
