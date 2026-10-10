import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar.win
import "../../widgets/Place.js" as Place

// Small volume / mic / layout OSD. Position comes from Settings → Звук → OSD.
PanelWindow {
    id: win

    property string kind: "volume"
    property bool shown: false
    readonly property bool winMode: Config.bar.style === "windows"   // Windows 11 volume pill
    readonly property string pos: winMode ? "bottom-center" : Config.osd.position || "bottom-center"
    readonly property bool compactLayout: kind === "layout"

    function show(k) {
        if (!Config.osd.enabled)
            return;
        kind = k;
        shown = true;
        hide.interval = k === "layout" ? Math.round(Config.osd.ms * 0.7) : Config.osd.ms;
        hide.restart();
    }

    screen: Shell.focusedScreen
    visible: shown || fade.running
    anchors.top: Place.top(pos)
    anchors.bottom: Place.bottom(pos)
    anchors.left: Place.left(pos)
    anchors.right: Place.right(pos)
    margins.top: Theme.u * 6
    margins.bottom: winMode ? 24 : Theme.u * 6
    margins.left: Theme.u * 6
    margins.right: Theme.u * 6
    implicitWidth: winMode ? winBox.width : box.width + Theme.u * 3
    implicitHeight: winMode ? winBox.height + 16 : box.height + Theme.u * 3
    // respect the bar's exclusive zone, but don't reserve space ourselves
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "angelos-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: win.winMode ? winBox : box
        radius: win.winMode ? winBox.radius : 0
    }

    Rectangle {
        id: winBox
        visible: win.winMode
        width: win.kind === "layout" ? 120 : 200
        height: 48
        radius: 8
        y: win.shown ? 0 : 16
        color: WinStyle.flyout
        border.width: 1
        border.color: WinStyle.flyoutLine
        opacity: win.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: WinStyle.fast
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: WinStyle.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: WinStyle.decelerate
            }
        }
        readonly property real level: win.kind === "mic" ? (Audio.micMuted ? 0 : Audio.micVolume) : (Audio.muted ? 0 : Math.min(1, Audio.volume))
        Row {
            anchors.centerIn: parent
            spacing: 14
            WinIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 16
                name: win.kind === "mic" ? (Audio.micMuted ? "mic_off-regular" : "mic-regular") : win.kind === "layout" ? "apps-regular" : Audio.muted || Audio.volume <= 0 ? "speaker_mute-regular" : Audio.volume < 0.34 ? "speaker_0-regular" : Audio.volume < 0.67 ? "speaker_1-regular" : "speaker_2-regular"
            }
            Rectangle {
                visible: win.kind !== "layout"
                anchors.verticalCenter: parent.verticalCenter
                width: 104
                height: 4
                radius: 2
                color: WinStyle.dark ? Qt.rgba(1, 1, 1, 0.54) : Qt.rgba(0, 0, 0, 0.45)
                Rectangle {
                    width: parent.width * winBox.level
                    height: parent.height
                    radius: 2
                    color: WinStyle.accent
                    Behavior on width {
                        NumberAnimation {
                            duration: 90
                        }
                    }
                }
            }
            WinText {
                anchors.verticalCenter: parent.verticalCenter
                width: win.kind === "layout" ? implicitWidth : 26
                horizontalAlignment: Text.AlignRight
                text: win.kind === "layout" ? Niri.layoutShort.toUpperCase() : Math.round(winBox.level * 100)
                strong: win.kind === "layout"
            }
        }
    }

    Timer {
        id: hide
        onTriggered: win.shown = false
    }

    Connections {
        target: Audio
        function onChanged(what) {
            win.show(what);
        }
    }
    Connections {
        target: Niri
        function onLayoutSwitched() {
            if (Config.osd.layout)
                win.show("layout");
        }
    }

    PxBox {
        id: box
        visible: !win.winMode
        width: row.implicitWidth + Theme.u * (win.compactLayout ? 10 : 14)
        height: win.compactLayout ? Theme.u * 15 : Theme.u * 17
        color: Theme.panel
        shadow: Config.appearance.shadows
        opacity: win.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                id: fade
                duration: Theme.fast
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.u * 4

            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: win.kind === "mic" ? (Audio.micMuted ? "micMute" : "mic") : win.kind === "layout" ? "keyboard" : (Audio.muted ? "speakerMute" : "speaker")
            }
            PxHearts {
                visible: win.kind !== "layout"
                anchors.verticalCenter: parent.verticalCenter
                count: 10
                pixel: Math.max(1, Theme.u - 1)
                value: win.kind === "mic" ? (Audio.micMuted ? 0 : Audio.micVolume) : (Audio.muted ? 0 : Math.min(1, Audio.volume))
                fill: Audio.volume > 1 && win.kind === "volume" ? Theme.danger : Theme.accent
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: win.kind === "layout" ? Niri.layoutShort : win.kind === "mic" ? (Audio.micMuted ? I18n.t("выкл", "off") : Math.round(Audio.micVolume * 100) + "%") : (Audio.muted ? I18n.t("тихо", "Quiet") : Math.round(Audio.volume * 100) + "%")
                font.bold: win.kind === "layout"
            }
        }
    }

    RightClickGuard {}
}
