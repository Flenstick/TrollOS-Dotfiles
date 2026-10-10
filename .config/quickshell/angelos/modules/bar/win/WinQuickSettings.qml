pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets

// Windows 11 quick settings: media card, six toggle tiles, the volume slider
// (› picks the output device), and a footer with the settings gear.
WinFlyout {
    id: root

    flyoutWidth: 360
    place: "right"
    panelId: "win-quick"
    readonly property bool hasMedia: !!Lyrics.player && Lyrics.title !== ""
    readonly property int mediaH: hasMedia ? 116 : 0
    property bool outputs: false
    contentHeight: outputs ? Math.min(460, 64 + Audio.sinks.length * 44 + 64) : mediaH + tilesH + 76 + 48
    readonly property int tilesH: 2 * 80 + 24
    onOpened: outputs = false

    Behavior on contentHeight {
        NumberAnimation {
            duration: WinStyle.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: WinStyle.decelerate
        }
    }

    readonly property var tiles: [
        {
            "label": Wifi.connected ? Wifi.connected.name : "Wi-Fi",
            "icon": "wifi_1-regular",
            "on": Wifi.hasWifi && Wifi.enabled,
            "off": !Wifi.hasWifi,
            "run": () => Wifi.setEnabled(!Wifi.enabled)
        },
        {
            "label": "Bluetooth",
            "icon": "bluetooth-regular",
            "on": Bt.enabled,
            "off": !Bt.available,
            "run": () => Bt.setEnabled(!Bt.enabled)
        },
        {
            "label": I18n.t("Энергосбережение", "Energy saver"),
            "icon": "battery_saver-regular",
            "on": PowerProfiles.profile === PowerProfile.PowerSaver,
            "run": () => PowerProfiles.profile = PowerProfiles.profile === PowerProfile.PowerSaver ? PowerProfile.Balanced : PowerProfile.PowerSaver
        },
        {
            "label": I18n.t("Не беспокоить", "Do not disturb"),
            "icon": "alert_snooze-regular",
            "on": Config.notifications.dnd,
            "run": () => Config.notifications.dnd = !Config.notifications.dnd
        },
        {
            "label": I18n.t("Микрофон", "Microphone"),
            "icon": Audio.micMuted ? "mic_off-regular" : "mic-regular",
            "on": !Audio.micMuted,
            "run": () => Audio.toggleMic()
        },
        {
            "label": I18n.t("Тёмный режим", "Dark mode"),
            "icon": "dark_theme-regular",
            "on": Theme.dark,
            "run": () => Config.appearance.mode = Theme.dark ? "light" : "dark"
        }
    ]

    // ---- main page ----
    Item {
        id: mainPage
        width: root.flyoutWidth
        height: root.contentHeight
        x: root.outputs ? -40 : 0
        opacity: root.outputs ? 0 : 1
        visible: opacity > 0
        Behavior on x {
            NumberAnimation {
                duration: WinStyle.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: WinStyle.decelerate
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: WinStyle.fast
            }
        }

        // media
        Item {
            visible: root.hasMedia
            x: 12
            y: 12
            width: parent.width - 24
            height: root.mediaH - 12
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: WinStyle.card
                border.width: 1
                border.color: WinStyle.controlLine
            }
            Rectangle {
                id: art
                x: 12
                y: 12
                width: 56
                height: 56
                radius: 4
                color: WinStyle.subtleHover
                clip: true
                Image {
                    anchors.fill: parent
                    source: Lyrics.artUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(112, 112)
                    asynchronous: true
                }
            }
            Column {
                x: art.x + art.width + 12
                y: 14
                width: parent.width - x - 12
                spacing: 2
                WinText {
                    width: parent.width
                    text: Lyrics.title
                    strong: true
                }
                WinText {
                    width: parent.width
                    text: Lyrics.artist
                    color: WinStyle.text2
                    font.pixelSize: WinStyle.caption
                }
                WinText {
                    width: parent.width
                    text: Lyrics.player ? (Lyrics.player.identity || "") : ""
                    color: WinStyle.text3
                    font.pixelSize: WinStyle.caption
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                spacing: 4
                Repeater {
                    model: [["previous-filled", () => Lyrics.player.previous()], [Lyrics.playing ? "pause-filled" : "play-filled", () => Lyrics.player.togglePlaying()], ["next-filled", () => Lyrics.player.next()]]
                    FlatButton {
                        required property var modelData
                        width: 36
                        height: 28
                        icon: modelData[0]
                        onClicked: if (Lyrics.player)
                            modelData[1]()
                    }
                }
            }
        }

        // tiles
        Grid {
            x: 24
            y: root.mediaH + 20
            columns: 3
            columnSpacing: 12
            rowSpacing: 8
            Repeater {
                model: root.tiles
                Column {
                    id: tile
                    required property var modelData
                    spacing: 6
                    width: 96
                    Rectangle {
                        width: 96
                        height: 48
                        radius: 4
                        opacity: tile.modelData.off ? 0.45 : 1
                        color: tile.modelData.on ? (tma.containsMouse ? WinStyle.accentHover : WinStyle.accent) : tma.pressed ? WinStyle.subtlePress : tma.containsMouse ? WinStyle.controlHover : WinStyle.control
                        border.width: 1
                        border.color: tile.modelData.on ? Qt.rgba(0, 0, 0, 0.1) : WinStyle.controlLine
                        Behavior on color {
                            ColorAnimation {
                                duration: WinStyle.fast
                            }
                        }
                        WinIcon {
                            anchors.centerIn: parent
                            name: tile.modelData.icon
                            size: 16
                            tone: tile.modelData.on ? (WinStyle.accentLight ? "black" : "white") : "auto"
                            scale: tma.pressed ? 0.85 : 1
                            Behavior on scale {
                                NumberAnimation {
                                    duration: WinStyle.fast
                                }
                            }
                        }
                        MouseArea {
                            id: tma
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !tile.modelData.off
                            onClicked: tile.modelData.run()
                        }
                    }
                    WinText {
                        width: 96
                        horizontalAlignment: Text.AlignHCenter
                        text: tile.modelData.label
                        font.pixelSize: WinStyle.caption
                    }
                }
            }
        }

        // volume
        Row {
            x: 16
            y: root.mediaH + root.tilesH + 16
            spacing: 4
            FlatButton {
                width: 40
                height: 40
                icon: Audio.muted || Audio.volume <= 0 ? "speaker_mute-regular" : Audio.volume < 0.34 ? "speaker_0-regular" : Audio.volume < 0.67 ? "speaker_1-regular" : "speaker_2-regular"
                onClicked: Audio.toggleMute()
            }
            WinSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: 248
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
            FlatButton {
                width: 36
                height: 40
                icon: "chevron_right-regular"
                onClicked: root.outputs = true
            }
        }

        // footer
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 48
            color: WinStyle.flyoutFoot
            Rectangle {
                width: parent.width
                height: 1
                color: WinStyle.divider
            }
            WinText {
                x: 24
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Audio.volume * 100) + " %" + (Wifi.connected ? "   ·   " + Wifi.connected.name : "")
                color: WinStyle.text2
                font.pixelSize: WinStyle.caption
            }
            FlatButton {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 32
                icon: "settings-regular"
                onClicked: {
                    root.hide();
                    Shell.openSettings("home");
                }
            }
        }
    }

    // ---- output devices ----
    Item {
        width: root.flyoutWidth
        height: root.contentHeight
        x: root.outputs ? 0 : 40
        opacity: root.outputs ? 1 : 0
        visible: opacity > 0
        Behavior on x {
            NumberAnimation {
                duration: WinStyle.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: WinStyle.decelerate
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: WinStyle.fast
            }
        }
        Row {
            x: 12
            y: 14
            spacing: 8
            FlatButton {
                width: 36
                height: 32
                icon: "chevron_left-regular"
                onClicked: root.outputs = false
            }
            WinText {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("Вывод звука", "Sound output")
                strong: true
            }
        }
        Column {
            x: 12
            y: 60
            width: parent.width - 24
            Repeater {
                model: Audio.sinks
                Item {
                    id: dev
                    required property var modelData
                    readonly property bool current: Audio.sink === modelData
                    width: parent.width
                    height: 44
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 4
                        color: dma.containsMouse ? WinStyle.subtleHover : dev.current ? WinStyle.subtlePress : "transparent"
                    }
                    Rectangle {
                        visible: dev.current
                        x: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 16
                        radius: 1.5
                        color: WinStyle.accent
                    }
                    WinIcon {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        name: "speaker_2-regular"
                    }
                    WinText {
                        x: 44
                        width: parent.width - 56
                        anchors.verticalCenter: parent.verticalCenter
                        text: Audio.nodeName(dev.modelData)
                    }
                    MouseArea {
                        id: dma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Audio.setDefaultSink(dev.modelData)
                    }
                }
            }
        }
    }

    component FlatButton: Rectangle {
        id: fb
        property string icon: ""
        signal clicked
        radius: 4
        color: fma.pressed ? WinStyle.subtlePress : fma.containsMouse ? WinStyle.subtleHover : "transparent"
        WinIcon {
            anchors.centerIn: parent
            name: fb.icon
            size: 16
        }
        MouseArea {
            id: fma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: fb.clicked()
        }
    }
}
