import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// IPC: qs -c angelos ipc call closeconfirm ask|cancel
// Mod+Q: если в окне (среди потомков его процесса) запущен claude или codex — спрашивает,
// закрывать ли; любое другое окно закрывает сразу. Повторный ask (ещё раз Mod+Q) — подтверждение.
Item {
    id: root
    property var plugin
    property var target: null     // окно niri {id, title, app_id}, которое закроем
    property var pending: null    // окно, для которого сейчас ищем claude/codex
    readonly property var guarded: ["claude", "codex"]

    function ask() {
        if (target) {
            confirm();
            return;
        }
        const w = Niri.focusedWindow;
        if (!w || pending)
            return;
        pending = {
            id: w.id,
            title: w.title || "",
            app_id: w.app_id || ""
        };
        // идём от процессов claude/codex вверх по родителям: их мало, а у Discord/Steam потомков сотни
        check.command = ["sh", "-c", 'for p in $(pgrep -x "$1"); do while [ "${p:-0}" -gt 1 ]; do [ "$p" = "$0" ] && exit 0; pp=; while read -r k v; do [ "$k" = PPid: ] && { pp=$v; break; }; done < /proc/$p/status 2>/dev/null; p=$pp; done; done; exit 1', String(w.pid), guarded.join("|")];
        check.running = true;
    }
    function confirm() {
        if (target)
            Niri.closeWindow(target.id);
        target = null;
    }
    function cancel() {
        target = null;
    }

    Process {
        id: check
        onExited: code => {
            const w = root.pending;
            root.pending = null;
            if (!w)
                return;
            if (code === 0)
                root.target = w;
            else
                Niri.closeWindow(w.id);
        }
    }

    IpcHandler {
        target: "closeconfirm"
        function ask(): void {
            root.ask();
        }
        function cancel(): void {
            root.cancel();
        }
    }

    PanelWindow {
        // takes input: the «close this tab?» question holds every click until it is answered
        id: win
        visible: !!root.target
        screen: Shell.focusedScreen
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: Qt.alpha(Theme.shadow, 0.35)
        WlrLayershell.namespace: "angelos-close-confirm"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible)
            keys.forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape || e.key === Qt.Key_N) {
                    root.cancel();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Y) {
                    root.confirm();
                    e.accepted = true;
                }
            }
        }

        PxWindow {
            id: dialog
            anchors.centerIn: parent
            width: Theme.u * 190
            height: titleHeight + col.implicitHeight + Theme.pad * 2 + Theme.u * 8
            title: "Закрыть окно?"
            icon: "warn"
            onCloseClicked: root.cancel()

            MouseArea {
                anchors.fill: parent    // клики по самому диалогу не считаются «мимо»
            }

            Column {
                id: col
                width: parent.width
                spacing: Theme.u * 5

                Row {
                    spacing: Theme.u * 5
                    width: parent.width
                    PxIcon {
                        name: "warn"
                        pixel: Theme.u * 2
                    }
                    PxText {
                        width: parent.width - Theme.u * 30
                        text: "Точно хотите закрыть эту вкладку?"
                        wrapMode: Text.Wrap
                    }
                }
                PxText {
                    width: parent.width
                    text: root.target ? (root.target.title || root.target.app_id) : ""
                    kind: "tiny"
                    dim: true
                    elide: Text.ElideRight
                }
                Row {
                    anchors.right: parent.right
                    spacing: Theme.u * 4
                    PxButton {
                        text: "Отмена"
                        onClicked: root.cancel()
                    }
                    PxButton {
                        text: "Закрыть"
                        accent: true
                        onClicked: root.confirm()
                    }
                }
            }
        }
        // a right click into the window's corner can crash Qt (widgets/RightClickGuard)
        RightClickGuard {}
    }
}
