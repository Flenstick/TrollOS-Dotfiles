pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.desktop
import qs.modules.y2k
import qs.widgets

// Two background-layer surfaces per screen:
//   angelos-wallpaper — the picture and the desktop widgets; niri keeps it in the
//                       backdrop (layer-rule place-within-backdrop): it does not
//                       slide with workspaces and shows once in the overview, but
//                       gets NO input at all
//   angelos-desktop   — transparent, drawn inside every workspace: right-click
//                       menu and invisible widget proxies that take the pointer
Variants {
    model: Shell.screens

    Scope {
        id: scope
        required property var modelData

        PanelWindow {
            screen: scope.modelData
            color: Theme.desk
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "angelos-wallpaper"

            WallpaperView {
                anchors.fill: parent
                screenName: scope.modelData.name
            }

            // live-wallpaper plugins draw here (Shell.wallpaperSlots), under the widgets
            Item {
                id: wallSlot
                anchors.fill: parent
                Component.onCompleted: {
                    const m = Object.assign({}, Shell.wallpaperSlots);
                    m[scope.modelData.name] = wallSlot;
                    Shell.wallpaperSlots = m;
                }
                Component.onDestruction: {
                    if (Shell.wallpaperSlots[scope.modelData.name] !== wallSlot)
                        return;
                    const m = Object.assign({}, Shell.wallpaperSlots);
                    delete m[scope.modelData.name];
                    Shell.wallpaperSlots = m;
                }
            }

            // desktop widgets (built-in + plugins): pinned with the wallpaper
            Item {
                id: widgetLayer
                anchors.fill: parent
                Repeater {
                    model: DesktopWidgets.uidsFor(scope.modelData.name)
                    DesktopWidgetHost {
                        required property string modelData
                        uid: modelData
                        screenName: scope.modelData.name
                        area: widgetLayer
                    }
                }
            }

            RightClickGuard {}
        }

        PanelWindow {
            id: win

            readonly property var modelData: scope.modelData
            screen: scope.modelData
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "angelos-desktop"

            readonly property bool sparkles: Config.y2k.sparkles && (!(Config.y2k.sparkleScreens || []).length || Config.y2k.sparkleScreens.includes(modelData.name))
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                hoverEnabled: win.sparkles
                onPositionChanged: m => {
                    if (win.sparkles)
                        trail.spawn(m.x, m.y);
                }
                onClicked: m => {
                    if (m.button === Qt.RightButton)
                        menu.openAt(m.x, m.y);
                    else {
                        menu.close();
                        DesktopWidgets.editMode = false;
                    }
                }
            }

            // input for the widgets drawn in the wallpaper surface (see WidgetProxy)
            Item {
                id: deskArea
                anchors.fill: parent
                Repeater {
                    model: DesktopWidgets.uidsFor(win.modelData.name)
                    WidgetProxy {
                        required property string modelData
                        uid: modelData
                        area: deskArea
                        onContextMenu: (x, y) => menu.openAt(x, y)
                    }
                }
            }

            // Y2K glitter behind the pointer (Settings → Y2K)
            SparkleTrail {
                id: trail
                anchors.fill: parent
                visible: win.sparkles
            }

            DesktopMenu {
                id: menu
                parentWindow: win
                Component.onCompleted: {
                    const m = Shell.desktopMenus;
                    m[win.modelData.name] = menu;
                    Shell.desktopMenus = m;
                }
            }

            RightClickGuard {}
        }
    }
}
