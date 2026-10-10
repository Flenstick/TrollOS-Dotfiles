pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// App dock for the macOS / Ubuntu / elementary layouts: pinned apps plus the
// running ones. Bottom: a floating centred shelf whose icons grow under the
// pointer; left: a full height strip. Click focuses (again — the next window
// of the app) or launches, middle click opens a new window, right click — menu.
PanelWindow {
    id: win

    required property var modelData
    readonly property string screenName: modelData.name
    readonly property bool left: Config.dock.position === "left"
    readonly property bool magnify: !left && Config.dock.magnify
    readonly property real maxScale: magnify ? 1.6 : 1
    readonly property int cell: Theme.u * Math.max(14, Math.min(40, Config.dock.size || 22))
    readonly property int spacing: Theme.u * 3
    readonly property int pad: Theme.u * 4
    readonly property int edgeGap: left ? 0 : Theme.u * 3
    // room above the shelf (bottom) / beside the strip (left) for grown icons and the name tag
    readonly property int headroom: Math.round(cell * (maxScale - 1)) + Theme.u * 22
    readonly property int thick: cell + pad * 2 + Theme.u * 4    // shelf height / strip width
    readonly property int count: entries.length + (Config.dock.appsButton ? 1 : 0)
    readonly property int baseLength: count * cell + Math.max(0, count - 1) * spacing + pad * 2 + (Config.dock.appsButton && entries.length ? spacing + Theme.u * 3 : 0)

    // ---- what is in the dock ----
    function keyOf(appId) {
        const e = appId ? DesktopEntries.heuristicLookup(appId) : null;
        return e ? e.id : appId || "?";
    }
    readonly property var pinnedIds: {
        const ids = (Config.dock.pinned || []).filter(id => StartApps.apps.some(a => a.id === id));
        return ids.length ? ids : StartApps.frequent.slice(0, 7).map(a => a.id);
    }
    readonly property var entries: {
        const out = [];
        const byKey = {};
        for (const id of pinnedIds) {
            const e = {
                "key": id,
                "app": StartApps.apps.find(a => a.id === id) || null,
                "appId": id,
                "pinned": true,
                "windows": []
            };
            byKey[id] = e;
            out.push(e);
        }
        for (const w of Niri.sortedWindows(Niri.windows)) {
            const k = keyOf(w.app_id);
            let e = byKey[k];
            if (!e) {
                if (!Config.dock.running)
                    continue;
                e = {
                    "key": k,
                    "app": DesktopEntries.heuristicLookup(w.app_id || "") || null,
                    "appId": w.app_id || "",
                    "pinned": false,
                    "windows": []
                };
                byKey[k] = e;
                out.push(e);
            }
            e.windows.push(w);
        }
        return out;
    }

    function activate(e, icon) {
        if (!e.windows.length) {
            launch(e, icon);
            return;
        }
        // the app is in front: go to its next window; otherwise bring back the last one
        const i = e.windows.findIndex(w => w.is_focused);
        const w = i >= 0 ? e.windows[(i + 1) % e.windows.length] : e.windows[0];
        Niri.focusWindow(w.id);
    }
    function launch(e, icon) {
        if (e.app) {
            StartApps.launch(e.app);
            if (icon)
                icon.hop();
        }
    }
    function togglePin(e) {
        const ids = pinnedIds.slice();
        const i = ids.indexOf(e.key);
        if (i >= 0)
            ids.splice(i, 1);
        else
            ids.push(e.key);
        Config.dock.pinned = ids;
    }

    // ---- window ----
    screen: modelData
    anchors {
        bottom: true
        left: win.left
        top: win.left
    }
    margins.bottom: edgeGap
    implicitWidth: left ? thick + headroom + Theme.u * 80 : Math.min(modelData.width, Math.round(baseLength + cell * (maxScale - 1) * 3 + Theme.u * 80))
    implicitHeight: left ? 0 : thick + headroom
    exclusiveZone: thick
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "angelos-dock"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region {
        item: box
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: box
    }

    // pointer along the dock, in the coordinates of the un-grown row (-1 = away);
    // measured on the whole window (fixed size), never on the growing shelf
    readonly property real hoverPos: magnify && hover.hovered ? hover.point.position.x - (width - baseLength) / 2 : -1
    // the growth eases in and out instead of snapping when the pointer comes or goes
    property real lastPos: -1
    onHoverPosChanged: if (hoverPos >= 0)
        lastPos = hoverPos
    property real magAmount: hoverPos >= 0 ? 1 : 0
    Behavior on magAmount {
        NumberAnimation {
            duration: Theme.fast
            easing.type: Easing.OutCubic
        }
    }
    readonly property real grownLength: {
        let sum = 0;
        for (let i = 0; i < count; i++)
            sum += cell * scaleAt(i);
        return sum + Math.max(0, count - 1) * spacing + pad * 2 + (Config.dock.appsButton && entries.length ? spacing + Theme.u * 3 : 0);
    }
    function centerAt(i) {
        const sep = Config.dock.appsButton && entries.length && i >= entries.length ? spacing + Theme.u * 3 : 0;
        return pad + i * (cell + spacing) + cell / 2 + sep;
    }
    function scaleAt(i) {
        if (!magnify || lastPos < 0 || magAmount <= 0)
            return 1;
        const d = Math.abs(lastPos - centerAt(i)) / (cell * 2.6);
        return 1 + (maxScale - 1) * magAmount * Math.max(0, Math.cos(Math.min(1, d) * Math.PI / 2));
    }

    Item {
    id: stage
    anchors.fill: parent
    HoverHandler {
        id: hover
    }

    PxBox {
        id: box
        readonly property real len: win.magnify ? win.grownLength : win.baseLength
        x: win.left ? 0 : Math.round((win.width - width) / 2)
        y: win.left ? Math.round((win.height - height) / 2) : win.height - height
        width: win.left ? win.thick : Math.round(len)
        height: win.left ? win.height : win.thick
        color: Theme.panel
        outline: !win.left
        shadow: !win.left && Config.appearance.shadows
        Behavior on width {
            enabled: !win.magnify
            NumberAnimation {
                duration: Theme.fast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            // the strip's edge line, like the taskbar's highlight
            visible: win.left
            anchors.right: parent.right
            width: Theme.u
            height: parent.height
            color: Theme.hi
        }

        Grid {
            id: grid
            columns: win.left ? 1 : Math.max(1, win.entries.length)
            x: win.pad
            y: win.left ? win.pad + Theme.u * 6 : 0
            spacing: win.spacing

            Repeater {
                model: win.entries
                DockIcon {
                    required property var modelData
                    required property int index
                    entry: modelData
                    scaleFactor: win.scaleAt(index)
                }
            }
        }

        // apps grid at the end (bottom) / the foot of the strip (left), like "Show apps"
        DockIcon {
            id: appsIcon
            visible: Config.dock.appsButton
            isApps: true
            entry: null
            scaleFactor: win.scaleAt(win.entries.length)
            x: win.left ? win.pad : box.width - win.pad - width
            y: win.left ? box.height - win.pad - Theme.u * 6 - height : 0
        }
        Rectangle {
            // separator before the apps button
            visible: !win.left && Config.dock.appsButton && win.entries.length > 0
            x: appsIcon.x - win.spacing / 2 - Theme.u * 2
            y: win.pad + Theme.u
            width: Theme.u
            height: win.cell
            color: Theme.lo
        }
    }
    }

    // name tag of the hovered icon
    PxBox {
        id: tag
        property var target: null
        property string text: ""
        visible: !!target && text !== "" && !menu.visible
        color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
        shadow: Config.appearance.shadows
        width: tagText.implicitWidth + Theme.u * 10
        height: tagText.implicitHeight + Theme.u * 6
        // mapToItem is not reactive: hoverPos / box.width re-run it while icons grow
        x: {
            if (!target || win.hoverPos < -1e9 || box.width < 0)
                return 0;
            const p = target.mapToItem(win.contentItem, 0, 0);
            return win.left ? box.width + Theme.u * 4 : Math.max(0, Math.min(win.width - width, p.x + target.width / 2 - width / 2));
        }
        y: {
            if (!target || win.hoverPos < -1e9 || box.width < 0)
                return 0;
            const p = target.mapToItem(win.contentItem, 0, 0);
            return win.left ? p.y + win.cell / 2 - height / 2 : p.y + win.pad + win.cell * (1 - target.s) - height - Theme.u * 4;
        }
        PxText {
            id: tagText
            anchors.centerIn: parent
            text: tag.text
        }
    }

    DockMenu {
        id: menu
        anchorItem: box
        above: !win.left
        dock: win
    }

    component DockIcon: Item {
        id: ic

        property var entry: null
        property bool isApps: false
        property real scaleFactor: 1
        readonly property var wins: entry ? entry.windows : []
        readonly property bool running: wins.length > 0
        readonly property bool focused: wins.some(w => w.is_focused)
        readonly property real s: scaleFactor
        readonly property string name: isApps ? I18n.t("Все приложения", "All apps") : entry && entry.app ? entry.app.name : entry && entry.windows.length ? (entry.windows[0].title || entry.appId) : entry ? entry.appId : ""

        width: win.cell * (win.left ? 1 : s)
        height: win.left ? win.cell : box.height - win.pad
        property real jump: 0

        function hop() {
            hopAnim.restart();
        }
        SequentialAnimation {
            id: hopAnim
            loops: 2
            NumberAnimation {
                target: ic
                property: "jump"
                to: win.cell * 0.45
                duration: 180
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: ic
                property: "jump"
                to: 0
                duration: 220
                easing.type: Easing.OutBounce
            }
        }

        Item {
            id: face
            width: win.cell
            height: win.cell
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.left ? 0 : win.pad - ic.jump
            transform: Translate {
                x: win.left ? ic.jump : 0
            }
            scale: ic.s * (mouse.pressed ? 0.92 : 1)
            transformOrigin: win.left ? Item.Center : Item.Bottom

            AppIcon {
                anchors.centerIn: parent
                visible: !ic.isApps
                appId: ic.entry ? ic.entry.appId : ""
                iconName: ic.entry && ic.entry.app && ic.entry.app.icon ? ic.entry.app.icon : ""
                size: Math.round(win.cell * win.maxScale)
                scale: 1 / win.maxScale
            }
            PxBox {
                visible: ic.isApps
                anchors.fill: parent
                anchors.margins: Theme.u
                color: mouse.containsMouse || Shell.startScreen === win.screenName ? Theme.mix(Theme.face, Theme.accent, 0.3) : Theme.face
                PxIcon {
                    anchors.centerIn: parent
                    name: "grid"
                    pixel: Math.max(1, Math.round(win.cell / 12))
                }
            }
        }

        // running marks: pixel dots under (bottom) / beside (left) the icon, one per window up to 3
        Grid {
            visible: ic.running
            columns: win.left ? 1 : 3
            spacing: Theme.u
            x: win.left ? -win.pad + Theme.u : (parent.width - width) / 2
            y: win.left ? (parent.height - height) / 2 : parent.height - height - Theme.u * 2
            Repeater {
                model: Math.min(3, ic.wins.length)
                Rectangle {
                    required property int index
                    readonly property int len: ic.focused && index === 0 ? Theme.u * 6 : Theme.u * 2
                    width: win.left ? Theme.u * 2 : len
                    height: win.left ? len : Theme.u * 2
                    color: ic.focused ? Theme.accent : Theme.text
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse) {
                    tag.target = ic;
                    tag.text = ic.name;
                } else if (tag.target === ic)
                    tag.target = null;
            }
            onClicked: mouse => {
                PopupManager.barPressed();
                if (ic.isApps) {
                    Shell.toggleStart(win.screenName);
                    return;
                }
                if (mouse.button === Qt.MiddleButton)
                    win.launch(ic.entry, ic);
                else if (mouse.button === Qt.RightButton)
                    menu.openFor(ic, ic.entry);
                else
                    win.activate(ic.entry, ic);
            }
        }
    }

    RightClickGuard {}
}
