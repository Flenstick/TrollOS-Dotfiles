import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Acrylic flyout above the Windows taskbar: rounded, hairline border, soft shadow,
// slides up and fades in with the Fluent decelerate curve. `place` puts it at the
// right screen edge (quick settings, calendar), centred on the button, or left.
PopupWindow {
    id: root

    required property Item anchorItem      // the taskbar's full width content item
    property Item button: null            // the button that opened it (centre / left placement)
    property string place: "right"        // right | center | left
    property int flyoutWidth: 360
    property int contentHeight: 200
    property int radius: 8
    property int gap: 12                  // between the taskbar and the flyout
    property string panelId: ""
    property bool grab: true
    property bool plain: false            // content draws its own cards (calendar): no frame, blur on cardA/cardB
    property Item cardA: null
    property Item cardB: null
    readonly property int pad: 28         // room for the shadow
    readonly property alias frame: frame
    default property alias content: frame.data
    readonly property string outputName: anchorItem && anchorItem.QsWindow.window && anchorItem.QsWindow.window.screen ? anchorItem.QsWindow.window.screen.name : ""
    signal opened

    Component.onCompleted: PopupManager.registerPopup(root)
    Component.onDestruction: PopupManager.unregisterPopup(root)

    function toggle(btn) {
        if (btn)
            button = btn;
        place_();
        PopupManager.toggle(root);
    }
    function show(btn) {
        if (btn)
            button = btn;
        place_();
        if (!visible)
            PopupManager.toggle(root);
    }
    function hide() {
        PopupManager.close(root);
    }
    function place_() {
        const W = anchorItem.width;
        let x = W - gap - flyoutWidth;
        if (place === "center" && button) {
            const p = button.mapToItem(anchorItem, 0, 0);
            x = Math.max(gap, Math.min(W - gap - flyoutWidth, p.x + button.width / 2 - flyoutWidth / 2));
        } else if (place === "left")
            x = button ? Math.max(gap, button.mapToItem(anchorItem, 0, 0).x) : gap;
        _x = x;
    }
    property real _x: 0
    // right-edge flyouts need no button, so IPC (`angelos panel win-quick`) can open them too
    anchor.rect.x: (place === "right" ? anchorItem.width - gap - flyoutWidth : _x) - pad
    anchor.rect.y: -gap + pad
    anchor.rect.width: 1
    anchor.rect.height: 1

    anchor.item: anchorItem
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Top | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: grab
    visible: false
    color: "transparent"
    implicitWidth: flyoutWidth + pad * 2
    implicitHeight: contentHeight + pad * 2

    property real reveal: 0
    onVisibleChanged: {
        if (visible) {
            if (PopupManager.active && PopupManager.active !== root)
                PopupManager.close(PopupManager.active);
            PopupManager.active = root;
            reveal = 0;
            revealAnim.restart();
            root.opened();
        } else if (PopupManager.active === root)
            PopupManager.active = null;
    }
    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: WinStyle.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: WinStyle.decelerate
    }

    mask: Region {
        item: frame
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: root.plain ? root.cardA : frame
        radius: root.radius
        // explicit window coordinates (an item here lands shifted by the shadow pad)
        Region {
            x: root.plain && root.cardB ? frame.x + root.cardB.x : 0
            y: root.plain && root.cardB ? frame.y + root.cardB.y : 0
            width: root.plain && root.cardB ? root.cardB.width : 0
            height: root.plain && root.cardB ? root.cardB.height : 0
            radius: root.radius
        }
    }

    RectangularShadow {
        visible: !root.plain
        anchors.fill: frame
        radius: root.radius
        blur: 28
        spread: 0
        offset.y: 8
        color: WinStyle.shadow
        opacity: frame.opacity
    }
    Rectangle {
        id: frame
        x: root.pad
        y: root.pad + (1 - root.reveal) * 36
        width: root.flyoutWidth
        height: root.contentHeight
        radius: root.radius
        color: root.plain ? "transparent" : WinStyle.flyout
        border.width: root.plain ? 0 : 1
        border.color: WinStyle.flyoutLine
        opacity: Math.min(1, root.reveal * 1.6)
        clip: !root.plain
        focus: true
        Keys.onEscapePressed: root.hide()
    }

    RightClickGuard {}
}
