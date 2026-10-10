pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Windows 11 context menu (jump lists, Win+X, taskbar, tray). Items:
// {text, icon (Fluent name or app icon via appIcon), hint, run(), separator, sub: [...] , checked}
// A DBus tray menu is shown by setting `handle` instead of `items`.
PopupWindow {
    id: root

    required property Item anchorItem
    property var items: []
    property var handle: null
    property var stack: []                 // submenus opened (drill-down)
    readonly property var dbusCurrent: stack.length && handle ? stack[stack.length - 1] : handle
    readonly property var list: handle ? [] : (stack.length ? stack[stack.length - 1] : items)
    readonly property int pad: 24
    property int minWidth: 200
    readonly property string outputName: anchorItem && anchorItem.QsWindow.window && anchorItem.QsWindow.window.screen ? anchorItem.QsWindow.window.screen.name : ""
    property string panelId: ""

    Component.onCompleted: PopupManager.registerPopup(root)
    Component.onDestruction: PopupManager.unregisterPopup(root)

    // open above `item` (taskbar buttons), its centre or at x within it
    function openAbove(item, list, atX) {
        handle = null;
        items = list;
        stack = [];
        const p = item.mapToItem(anchorItem, 0, 0);
        anchor.rect.x = (atX !== undefined ? p.x + atX : p.x + item.width / 2) - pad;
        anchor.rect.y = p.y - 8 + pad;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
        centred = atX === undefined;
        reopen();
    }
    function openTray(item, menuHandle) {
        items = [];
        stack = [];
        handle = menuHandle;
        const p = item.mapToItem(anchorItem, 0, 0);
        anchor.rect.x = p.x + item.width / 2 - pad;
        anchor.rect.y = p.y - 8 + pad;
        centred = true;
        reopen();
    }
    property bool centred: true
    function reopen() {
        if (visible) {
            visible = false;
            Qt.callLater(() => {
                anchor.updateAnchor();
                visible = true;
            });
        } else
            visible = true;
    }
    function run(it) {
        if (it.sub) {
            stack = stack.concat([it.sub]);
            return;
        }
        visible = false;
        if (it.run)
            it.run();
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: centred ? Edges.Top : Edges.Top | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: frame.width + pad * 2
    implicitHeight: frame.height + pad * 2

    property real reveal: 0
    onVisibleChanged: {
        if (visible) {
            if (PopupManager.active && PopupManager.active !== root)
                PopupManager.close(PopupManager.active);
            PopupManager.active = root;
            revealAnim.restart();
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
        item: frame
        radius: 8
    }

    QsMenuOpener {
        id: opener
        menu: root.dbusCurrent
    }
    // DBus menus become plain item lists
    readonly property var shown: {
        if (!handle)
            return list;
        const out = [];
        const kids = opener.children ? opener.children.values : [];
        for (const m of kids)
            out.push(m.isSeparator ? {
                "separator": true
            } : {
                "text": (m.text || "").replace(/_(?!_)/, ""),
                "iconUrl": m.icon || "",
                "enabled": m.enabled,
                "checked": m.buttonType !== QsMenuButtonType.None && m.checkState === Qt.Checked,
                "dbus": m
            });
        return out;
    }
    readonly property bool anyIcon: shown.some(it => it.icon || it.appIcon || it.iconUrl || it.checked !== undefined && it.checked)

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
        y: root.pad + (1 - root.reveal) * 12
        width: Math.max(root.minWidth, col.implicitWidth)
        height: col.implicitHeight + 8
        radius: 8
        color: WinStyle.menu
        border.width: 1
        border.color: WinStyle.flyoutLine
        opacity: Math.min(1, root.reveal * 1.5)
        focus: true
        Keys.onEscapePressed: {
            if (root.stack.length)
                root.stack = root.stack.slice(0, -1);
            else
                root.visible = false;
        }

        Column {
            id: col
            y: 4
            width: frame.width

            Item {
                visible: root.stack.length > 0
                width: parent.width
                height: visible ? 36 : 0
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    radius: 4
                    color: backArea.containsMouse ? WinStyle.subtleHover : "transparent"
                }
                WinIcon {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron_left-regular"
                }
                WinText {
                    x: 44
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("Назад", "Back")
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.stack = root.stack.slice(0, -1)
                }
            }

            Repeater {
                model: root.shown
                Item {
                    id: row
                    required property var modelData
                    readonly property bool sep: !!modelData.separator
                    readonly property bool off: modelData.enabled === false
                    width: col.width
                    implicitWidth: (root.anyIcon ? 44 : 14) + label.implicitWidth + (hintText.visible ? hintText.implicitWidth + 24 : 0) + (modelData.sub || (modelData.dbus && modelData.dbus.hasChildren) ? 30 : 0) + 20
                    height: sep ? 9 : 36

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
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        radius: 4
                        color: area.pressed ? WinStyle.subtlePress : area.containsMouse && !row.off ? WinStyle.subtleHover : "transparent"
                    }
                    WinIcon {
                        visible: !row.sep && !!row.modelData.icon
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.icon || ""
                        opacity: row.off ? 0.4 : 1
                    }
                    AppIcon {
                        visible: !row.sep && !!row.modelData.appIcon
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        appId: row.modelData.appIcon || ""
                        iconName: row.modelData.appIconName || ""
                        size: 16
                    }
                    Image {
                        visible: !row.sep && !!row.modelData.iconUrl && !row.modelData.checked
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        source: row.modelData.iconUrl || ""
                    }
                    WinText {
                        visible: !row.sep && row.modelData.checked === true
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                    }
                    WinText {
                        id: label
                        visible: !row.sep
                        x: root.anyIcon ? 44 : 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text || ""
                        color: row.off ? WinStyle.textOff : WinStyle.text
                    }
                    WinText {
                        id: hintText
                        visible: !row.sep && !!row.modelData.hint
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.hint || ""
                        color: WinStyle.text3
                        font.pixelSize: WinStyle.caption
                    }
                    WinIcon {
                        visible: !row.sep && (!!row.modelData.sub || !!row.modelData.dbus && row.modelData.dbus.hasChildren)
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron_right-regular"
                        size: 12
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        enabled: !row.sep && !row.off
                        hoverEnabled: true
                        onClicked: {
                            const m = row.modelData;
                            if (m.dbus) {
                                if (m.dbus.hasChildren)
                                    root.stack = root.stack.concat([m.dbus]);
                                else {
                                    m.dbus.triggered();
                                    root.visible = false;
                                }
                            } else
                                root.run(m);
                        }
                    }
                }
            }
        }
    }

    RightClickGuard {}
}
