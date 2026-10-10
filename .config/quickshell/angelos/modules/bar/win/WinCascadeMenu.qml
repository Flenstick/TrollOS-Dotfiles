pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Windows 11 context menu with cascading flyouts (desktop right click).
// items: [{label, icon (angelOS name → Fluent), color, hint, sub: [...] , checkable,
//          checked (bool or function), enabled, keepOpen, separator, run}]
PopupWindow {
    id: root

    property var items: []
    property var parentMenu: null            // the menu this one flies out of
    property int level: 0
    readonly property int pad: 24
    signal done

    function iconUrl(it) {
        if (it.iconUrl)
            return it.iconUrl;
        const n = it.icon ? (WinStyle.fluentIcon(it.icon) || it.icon) : "";
        if (!n)
            return "";
        if (it.color)
            return Qt.resolvedUrl("icons/c/" + n.replace(/-regular$/, "") + "-" + String(it.color).replace("#", "") + ".svg");
        return Qt.resolvedUrl("icons/" + (WinStyle.dark ? "d/" : "l/") + n + ".svg");
    }
    function isChecked(it) {
        return typeof it.checked === "function" ? it.checked() : !!it.checked;
    }
    property int tick: 0                       // re-reads checked() after a keepOpen click
    function closeAll() {
        if (child)
            child.visible = false;
        visible = false;
        if (parentMenu)
            parentMenu.closeAll();
    }
    function trigger(it) {
        if (it.sub)
            return openSub(rowFor(it), it.sub);
        if (it.enabled === false)
            return;
        if (it.run)
            it.run();
        if (it.keepOpen)
            tick++;
        else {
            closeAll();
            done();
        }
    }
    property var rows: []
    function rowFor(it) {
        return rows.find(r => r.modelData === it) || null;
    }
    function openSub(row, list) {
        if (!row)
            return;
        ensureChild();
        if (!child)
            return;
        child.items = list;
        child.anchor.item = row;
        child.anchor.rect.x = row.width - 4;
        child.anchor.rect.y = -4 - child.pad;
        child.anchor.rect.width = 1;
        child.anchor.rect.height = 1;
        if (child.visible) {
            child.visible = false;
            Qt.callLater(() => child.visible = true);
        } else
            child.visible = true;
    }

    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: frame.width + pad * 2
    implicitHeight: frame.height + pad * 2
    onVisibleChanged: {
        if (visible)
            revealAnim.restart();
        else if (child)
            child.visible = false;
        if (level === 0) {
            if (visible) {
                if (PopupManager.active && PopupManager.active !== root)
                    PopupManager.close(PopupManager.active);
                PopupManager.active = root;
            } else if (PopupManager.active === root)
                PopupManager.active = null;
        }
    }
    property real reveal: 1
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
        x: frame.x
        y: frame.y
        width: frame.width
        height: frame.height
        radius: 8
    }

    // the flyout of this menu, made on first use (a component may not contain itself)
    property var child: null
    function ensureChild() {
        if (child)
            return;
        const c = Qt.createComponent(Qt.resolvedUrl("WinCascadeMenu.qml"));
        child = c.createObject(root, {
            "parentMenu": root,
            "level": root.level + 1
        });
        if (child)
            child.done.connect(root.done);
    }
    Timer {
        id: hoverTimer
        property Item row: null
        interval: 250
        onTriggered: {
            if (!row || !row.hovered)
                return;
            if (row.modelData.sub)
                root.openSub(row, row.modelData.sub);
            else if (root.child)
                root.child.visible = false;
        }
    }

    RectangularShadow {
        anchors.fill: frame
        radius: 8
        blur: 22
        offset.y: 6
        color: WinStyle.shadow
        opacity: frame.opacity
    }
    Rectangle {
        id: frame
        x: root.pad
        y: root.pad + (1 - root.reveal) * -10
        width: Math.max(240, ...root.rows.map(r => r.implicitWidth))
        height: col.implicitHeight + 8
        radius: 8
        color: WinStyle.menu
        border.width: 1
        border.color: WinStyle.flyoutLine
        opacity: Math.min(1, root.reveal * 1.5)
        focus: true
        Keys.onEscapePressed: root.visible = false

        Column {
            id: col
            y: 4
            width: frame.width
            Repeater {
                model: root.items
                Item {
                    id: row
                    required property var modelData
                    readonly property bool sep: !!modelData.separator
                    readonly property bool off: modelData.enabled === false
                    readonly property bool hovered: ma.containsMouse
                    readonly property bool isChecked: root.tick >= 0 && root.isChecked(modelData)
                    Component.onCompleted: root.rows = root.rows.concat([row])
                    Component.onDestruction: root.rows = root.rows.filter(r => r !== row)
                    width: col.width
                    implicitWidth: 44 + label.implicitWidth + (hint.visible ? hint.implicitWidth + 28 : 0) + 40
                    height: sep ? 9 : 32
                    Rectangle {
                        visible: row.sep
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: WinStyle.divider
                    }
                    Rectangle {
                        visible: !row.sep
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        radius: 4
                        color: ma.pressed ? WinStyle.subtlePress : (ma.containsMouse || root.child && root.child.visible && root.child.anchor.item === row) && !row.off ? WinStyle.subtleHover : "transparent"
                    }
                    Image {
                        visible: !row.sep && !row.isChecked && source != ""
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        sourceSize: Qt.size(32, 32)
                        source: row.sep ? "" : root.iconUrl(row.modelData)
                        opacity: row.off ? 0.4 : 1
                    }
                    WinText {
                        visible: !row.sep && row.isChecked
                        x: 15
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                    }
                    WinText {
                        id: label
                        visible: !row.sep
                        x: 44
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label || ""
                        color: row.off ? WinStyle.textOff : WinStyle.text
                    }
                    WinText {
                        id: hint
                        visible: !row.sep && !!row.modelData.hint && !row.modelData.sub
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.hint || ""
                        color: WinStyle.text3
                        font.pixelSize: 12
                    }
                    WinIcon {
                        visible: !row.sep && !!row.modelData.sub
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron_right-regular"
                        size: 12
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        enabled: !row.sep
                        hoverEnabled: true
                        onContainsMouseChanged: if (containsMouse) {
                            hoverTimer.row = row;
                            hoverTimer.restart();
                        }
                        onClicked: root.trigger(row.modelData)
                    }
                }
            }
        }
    }

    RightClickGuard {}
}
