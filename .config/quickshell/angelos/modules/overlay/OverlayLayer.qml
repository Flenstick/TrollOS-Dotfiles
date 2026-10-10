pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Mod+G overlay: one overlay-layer surface per screen. Open — dimmed screen,
// the overlay.exe toolbar and every item with its title bar; closed — only the
// pinned items, and the surface takes input just over the "clickable" ones.
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property bool active: Overlay.open && Overlay.screen === modelData.name
        readonly property var mine: {
            Overlay.revision;
            return Overlay.items.filter(i => Overlay.screenOf(i) === win.modelData.name);
        }
        readonly property bool anyPinned: mine.some(i => i.pinned)
        readonly property var mineIds: mine.map(i => i.id)

        screen: modelData
        visible: !Shell.locked && (active || anyPinned)
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: active ? (Shell.dev ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : hitItems.length ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // input only where it is wanted: everywhere while open, otherwise over
        // pinned items marked clickable (an empty region lets every click through)
        property var hitItems: []
        property var hitRegions: []
        function updateHits() {
            const list = [];
            for (let i = 0; i < rep.count; i++) {
                const it = rep.itemAt(i);
                if (it && it.clickableNow)
                    list.push(it);
            }
            if (list.length === hitItems.length && list.every((it, i) => it === hitItems[i]))
                return;
            const old = hitRegions;
            hitItems = list;
            hitRegions = list.map(it => regionComp.createObject(win, {
                    "item": it
                }));
            old.forEach(r => r.destroy());
        }
        Component {
            id: regionComp
            Region {}
        }
        Connections {
            target: Overlay
            function onRevisionChanged() {
                hitTimer.restart();
            }
            function onOpenChanged() {
                hitTimer.restart();
            }
        }
        Timer {
            id: hitTimer
            interval: 0
            onTriggered: win.updateHits()
        }
        mask: Region {
            item: win.active ? root : null
            regions: win.hitRegions
        }

        BackgroundEffect.blurRegion: win.active && Config.appearance.blur ? blurRegion : null
        Region {
            id: blurRegion
            item: toolbar
        }

        Item {
            id: root
            anchors.fill: parent
            focus: win.active
            Keys.onEscapePressed: Overlay.open = false

            // dim + click on empty space closes
            Rectangle {
                anchors.fill: parent
                color: Theme.shadow
                opacity: win.active ? 0.35 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.fast
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: win.active
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: Overlay.open = false
            }

            // drop files (pictures, GIFs, videos) or text from anywhere
            DropArea {
                anchors.fill: parent
                enabled: win.active
                onEntered: d => d.accept(Qt.CopyAction)
                onDropped: d => {
                    let added = false;
                    if (d.hasUrls)
                        d.urls.forEach(u => {
                            if (Overlay.addMedia(String(u)))
                                added = true;
                        });
                    if (!added && d.hasText && d.text.trim() !== "")
                        Overlay.addNote(d.text.trim());
                    d.acceptProposedAction();
                }
            }

            Repeater {
                id: rep
                model: ScriptModel {
                    values: win.mineIds
                }
                delegate: OverlayItem {
                    active: win.active
                    onClickableNowChanged: hitTimer.restart()
                }
                onCountChanged: hitTimer.restart()
            }

            PxWindow {
                id: toolbar
                visible: win.active
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.u * 20
                width: Math.min(parent.width - Theme.u * 20, tools.implicitWidth + Theme.pad * 2 + Theme.u * 6)
                height: titleHeight + tools.implicitHeight + hint.implicitHeight + Theme.pad * 3 + Theme.u * 6
                compact: true
                title: I18n.exe("overlay")
                icon: "layers"
                onCloseClicked: Overlay.open = false

                MouseArea {
                    anchors.fill: parent
                }
                Row {
                    id: tools
                    spacing: Theme.u * 3
                    PxButton {
                        icon: "document"
                        text: I18n.t("Заметка", "Note")
                        onClicked: Overlay.addNote("")
                    }
                    PxButton {
                        icon: "image"
                        text: I18n.t("Картинка / GIF / видео", "Picture / GIF / video")
                        onClicked: Overlay.pickMedia()
                    }
                    PxButton {
                        icon: "package"
                        text: I18n.t("Из буфера", "From clipboard")
                        enabled: Clipboard.history.length > 0
                        onClicked: Overlay.addFromClipboard()
                    }
                    PxButton {
                        icon: "trash"
                        visible: Overlay.items.some(i => !i.pinned)
                        text: I18n.t("Убрать незакреплённые", "Clear unpinned")
                        onClicked: Overlay.clearUnpinned()
                    }
                }
                PxText {
                    id: hint
                    y: tools.height + Theme.u * 4
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    kind: "tiny"
                    dim: true
                    text: I18n.t("булавка — остаётся на экране после Win+G · мышка — кликабельно · колёсико по заголовку — прозрачность · Ctrl+колёсико — размер текста · файлы можно перетащить сюда", "pin — stays on screen after Win+G · mouse — clickable · wheel on title — opacity · Ctrl+wheel — text size · drop files here")
                }
            }
        }

        RightClickGuard {}
    }
}
