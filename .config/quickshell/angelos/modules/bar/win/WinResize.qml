pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.widgets
import qs.services

// Windows-style resizing for the Windows 11 copy: niri runs with prefer-no-csd, so
// windows have no edges to grab. A thin layer frames the focused window; its
// edges and corners show resize cursors and dragging them sets the window size
// over niri IPC (tiled: column width / window height — the column stays centred,
// so the edge follows the pointer at twice the speed; floating: size and position).
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property int grip: 6            // edge thickness outside the window
        readonly property var fw: Niri.focusedWindow
        readonly property var ws: fw ? Niri.workspaceById(fw.workspace_id) : null
        readonly property bool here: !!ws && ws.output === modelData.name && ws.is_active
        readonly property var live: here ? WinGeom.rectsOn(modelData, false)[fw.id] || null : null
        // while dragging the frame stays put (the pointer grab keeps the events coming)
        property var frozen: null
        readonly property var r: frozen || live
        readonly property bool blocked: !fw || Niri.overviewOpen || MetaTap.coversOutput(fw) || !!fw.is_fullscreen || Shell.startScreen !== "" || PopupManager.active !== null

        // mapped all the time (no map / unmap on every focus change); off = no input, 1 px
        readonly property bool on: here && !!r && !blocked && r.width > 60 && r.height > 60
        visible: true
        screen: modelData
        anchors {
            top: true
            left: true
        }
        margins.left: on ? Math.round(r.x) - grip : 0
        margins.top: on ? Math.round(r.y) - grip : 0
        implicitWidth: on ? Math.round(r.width) + grip * 2 : 1
        implicitHeight: on ? Math.round(r.height) + grip * 2 : 1
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-resize"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // input only on the frame, never over the window itself
        mask: Region {
            x: 0
            y: 0
            width: win.on ? win.width : 0
            height: win.on ? win.height : 0
            Region {
                intersection: Intersection.Subtract
                x: win.grip
                y: win.grip
                width: win.width - win.grip * 2
                height: win.height - win.grip * 2
            }
        }

        // drag state
        property var start: null        // {mx, my, w, h, x, y}
        property real lastSent: 0
        function send(nw, nh, dxPos, dyPos) {
            const w = fw;
            if (!w)
                return;
            if (nw !== null)
                Niri.action("SetWindowWidth", {
                    "id": w.id,
                    "change": {
                        "SetFixed": Math.max(120, Math.round(nw))
                    }
                });
            if (nh !== null)
                Niri.action("SetWindowHeight", {
                    "id": w.id,
                    "change": {
                        "SetFixed": Math.max(80, Math.round(nh))
                    }
                });
            if (w.is_floating && (dxPos || dyPos))
                Niri.action("MoveFloatingWindow", {
                    "id": w.id,
                    "x": {
                        "AdjustFixed": dxPos || 0
                    },
                    "y": {
                        "AdjustFixed": dyPos || 0
                    }
                });
        }

        component Grip: MouseArea {
            id: g
            property int ex: 0          // -1 left, 1 right, 0 none
            property int ey: 0          // -1 top, 1 bottom
            hoverEnabled: true
            preventStealing: true
            cursorShape: ex !== 0 && ey !== 0 ? (ex === ey ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor) : ex !== 0 ? Qt.SizeHorCursor : Qt.SizeVerCursor
            property real pendW: -1
            property real pendH: -1
            property real movedX: 0
            property real movedY: 0
            onPressed: m => {
                win.frozen = win.live;
                win.start = {
                    "mx": x + m.x,
                    "my": y + m.y,
                    "w": win.r.width,
                    "h": win.r.height
                };
                movedX = 0;
                movedY = 0;
            }
            onPositionChanged: m => {
                if (!pressed || !win.start)
                    return;
                const px = x + m.x, py = y + m.y;
                const dx = px - win.start.mx, dy = py - win.start.my;
                const floating = !!win.fw && win.fw.is_floating;
                // a centred tiled column grows on both sides: twice the pointer's way
                const kx = floating ? 1 : (WinGeom.centred ? 2 : 1);
                pendW = ex !== 0 ? win.start.w + ex * dx * kx : -1;
                pendH = ey !== 0 ? win.start.h + ey * dy * (floating ? 1 : 1) : -1;
                if (!throttle.running)
                    throttle.start();
            }
            onReleased: {
                throttle.stop();
                flush();
                win.start = null;
                win.frozen = null;
            }
            function flush() {
                if (pendW < 0 && pendH < 0)
                    return;
                const floating = !!win.fw && win.fw.is_floating;
                // floating, left / top edges: the opposite edge stays where it was
                let mx = 0, my = 0;
                if (floating && ex < 0 && pendW > 0) {
                    const want = -(pendW - win.start.w);
                    mx = want - movedX;
                    movedX = want;
                }
                if (floating && ey < 0 && pendH > 0) {
                    const want = -(pendH - win.start.h);
                    my = want - movedY;
                    movedY = want;
                }
                win.send(pendW >= 0 ? pendW : null, pendH >= 0 ? pendH : null, mx, my);
                pendW = -1;
                pendH = -1;
            }
            Timer {
                id: throttle
                interval: 16
                onTriggered: g.flush()
            }
        }

        readonly property int corner: 14
        // edges
        Grip {
            ex: -1
            x: 0
            y: win.corner
            width: win.grip
            height: win.height - win.corner * 2
        }
        Grip {
            ex: 1
            x: win.width - win.grip
            y: win.corner
            width: win.grip
            height: win.height - win.corner * 2
        }
        Grip {
            ey: -1
            x: win.corner
            y: 0
            width: win.width - win.corner * 2
            height: win.grip
        }
        Grip {
            ey: 1
            x: win.corner
            y: win.height - win.grip
            width: win.width - win.corner * 2
            height: win.grip
        }
        // corners
        Grip {
            ex: -1
            ey: -1
            x: 0
            y: 0
            width: win.corner
            height: win.corner
        }
        Grip {
            ex: 1
            ey: -1
            x: win.width - win.corner
            y: 0
            width: win.corner
            height: win.corner
        }
        Grip {
            ex: -1
            ey: 1
            x: 0
            y: win.height - win.corner
            width: win.corner
            height: win.corner
        }
        Grip {
            ex: 1
            ey: 1
            x: win.width - win.corner
            y: win.height - win.corner
            width: win.corner
            height: win.corner
        }
        // a right click into the window's corner can crash Qt (widgets/RightClickGuard)
        RightClickGuard {}
    }
}
