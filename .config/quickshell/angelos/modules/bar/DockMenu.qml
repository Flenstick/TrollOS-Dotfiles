pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Right-click menu of a dock icon: the app's windows, a new window, pin / unpin, close all.
PopupWindow {
    id: root

    required property Item anchorItem
    required property var dock             // DockWindow: launch, togglePin, left
    property bool above: true
    property var entry: null
    Component.onCompleted: PopupManager.registerPopup(root)
    Component.onDestruction: PopupManager.unregisterPopup(root)

    property bool reopening: false
    function openFor(item, e) {
        entry = e;
        const p = item.mapToItem(anchorItem, 0, 0);
        if (dock.left) {
            anchor.rect.x = anchorItem.width;
            anchor.rect.y = p.y;
            anchor.rect.width = 1;
            anchor.rect.height = item.height;
        } else {
            anchor.rect.x = p.x + item.width / 2;
            anchor.rect.y = 0;
            anchor.rect.width = 1;
            anchor.rect.height = 1;
        }
        if (!visible && !reopening) {
            visible = true;
            return;
        }
        visible = false;
        if (reopening)
            return;
        reopening = true;
        Qt.callLater(() => {
            if (!reopening)
                return;
            reopening = false;
            anchor.updateAnchor();
            visible = true;
        });
    }
    function run(fn) {
        const e = entry;
        reopening = false;
        visible = false;
        if (e)
            fn(e);
    }

    anchor.item: anchorItem
    anchor.edges: dock.left ? Edges.Top | Edges.Right : Edges.Top
    anchor.gravity: dock.left ? Edges.Bottom | Edges.Right : Edges.Top
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    grabFocus: !Shell.demo
    visible: false
    color: "transparent"
    implicitWidth: frame.width + Theme.u * 3
    implicitHeight: frame.height + Theme.u * 3
    onVisibleChanged: {
        if (visible) {
            if (PopupManager.active && PopupManager.active !== root)
                PopupManager.close(PopupManager.active);
            PopupManager.active = root;
        } else if (PopupManager.active === root)
            PopupManager.active = null;
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: frame
    }

    PxBox {
        id: frame
        width: Math.min(Theme.u * 200, Math.max(Theme.u * 130, ...column.children.map(c => c.implicitWidth || 0))) + inset * 2
        height: column.implicitHeight + inset * 2
        color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
        shadow: Config.appearance.shadows
        focus: true
        Keys.onEscapePressed: root.visible = false

        Column {
            id: column
            width: parent.width - frame.inset * 2

            Row {
                width: parent.width
                height: Theme.u * 16
                spacing: Theme.u * 4
                leftPadding: Theme.u * 5
                AppIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    appId: root.entry ? root.entry.appId : ""
                    iconName: root.entry && root.entry.app && root.entry.app.icon ? root.entry.app.icon : ""
                    size: Theme.u * 9
                }
                PxText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: column.width - Theme.u * 24
                    text: root.entry ? (root.entry.app ? root.entry.app.name : root.entry.appId) : ""
                    elide: Text.ElideRight
                    font.bold: true
                }
            }
            PxMenuItem {
                separator: true
            }
            // the app's windows: click to go there
            Repeater {
                model: root.entry ? root.entry.windows.slice(0, 8) : []
                PxMenuItem {
                    required property var modelData
                    text: modelData.title || modelData.app_id || "?"
                    icon: "window"
                    checked: modelData.is_focused
                    hint: {
                        const ws = Niri.workspaceById(modelData.workspace_id);
                        return ws ? I18n.t("стол ", "desk ") + ws.idx : "";
                    }
                    onTriggered: root.run(() => Niri.focusWindow(modelData.id))
                }
            }
            PxMenuItem {
                visible: !!root.entry && root.entry.windows.length > 0
                height: visible ? implicitHeight : 0
                separator: true
            }
            PxMenuItem {
                visible: !!root.entry && !!root.entry.app
                height: visible ? implicitHeight : 0
                text: I18n.t("Новое окно", "New window")
                icon: "plus"
                hint: I18n.t("средняя кнопка", "middle click")
                onTriggered: root.run(e => root.dock.launch(e, null))
            }
            PxMenuItem {
                visible: !!root.entry && !!root.entry.app
                height: visible ? implicitHeight : 0
                text: root.entry && root.entry.pinned ? I18n.t("Открепить от дока", "Unpin from dock") : I18n.t("Закрепить в доке", "Pin to dock")
                icon: "pin"
                onTriggered: root.run(e => root.dock.togglePin(e))
            }
            PxMenuItem {
                visible: !!root.entry && root.entry.windows.length > 0
                height: visible ? implicitHeight : 0
                text: root.entry && root.entry.windows.length > 1 ? I18n.t("Закрыть все окна: ", "Close all windows: ") + root.entry.windows.length : I18n.t("Закрыть", "Close")
                icon: "close"
                onTriggered: root.run(e => e.windows.forEach(w => Niri.closeWindow(w.id)))
            }
            PxMenuItem {
                separator: true
            }
            PxMenuItem {
                text: I18n.t("Настроить док…", "Dock settings…")
                icon: "gear"
                onTriggered: root.run(() => Shell.openSettings("layouts"))
            }
        }
    }

    RightClickGuard {}
}
