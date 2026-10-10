pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The volume mixer on the bar. One fixed size: devices on top, programs in a scrolling
// list below — the window no longer grows and shrinks (and jumps around its anchor)
// whenever a program starts or stops playing, or angelOS clicks (Audio.appStreams).
BarPopup {
    id: root

    title: I18n.exe(I18n.t("звук", "audio"))
    icon: "speaker"
    contentWidth: Theme.u * 170
    contentHeight: Theme.u * 214

    readonly property int rowH: Theme.u * 12

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 5

        PxText {
            kind: "title"
            text: I18n.t("Выход", "Output")
        }
        PxCombo {
            width: parent.width
            model: Audio.sinks.map(n => ({
                        "label": Audio.nodeName(n),
                        "value": n.id
                    }))
            currentValue: Audio.sink ? Audio.sink.id : -1
            onActivated: v => Audio.setDefaultSink(Audio.sinks.find(n => n.id === v))
        }
        Row {
            width: parent.width
            height: root.rowH
            spacing: Theme.u * 3
            PxButton {
                compact: true
                anchors.verticalCenter: parent.verticalCenter
                icon: Audio.muted ? "speakerMute" : "speaker"
                onClicked: Audio.toggleMute()
            }
            PxSlider {
                width: parent.width - Theme.u * 20
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1.5
                value: Audio.volume
                valueScale: 100
                suffix: "%"
                onMoved: v => Audio.setVolume(v)
            }
        }
        PxText {
            kind: "title"
            text: I18n.t("Микрофон", "Microphone")
        }
        // always there (greyed out with one microphone): a combo that comes and goes moved everything under it
        PxCombo {
            width: parent.width
            enabled: Audio.sources.length > 1
            model: Audio.sources.map(n => ({
                        "label": Audio.nodeName(n),
                        "value": n.id
                    }))
            currentValue: Audio.source ? Audio.source.id : -1
            onActivated: v => Audio.setDefaultSource(Audio.sources.find(n => n.id === v))
        }
        Row {
            width: parent.width
            height: root.rowH
            spacing: Theme.u * 3
            PxButton {
                compact: true
                anchors.verticalCenter: parent.verticalCenter
                icon: Audio.micMuted ? "micMute" : "mic"
                onClicked: Audio.toggleMic()
            }
            PxSlider {
                width: parent.width - Theme.u * 20
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1.5
                value: Audio.micVolume
                valueScale: 100
                suffix: "%"
                onMoved: v => {
                    if (Audio.source && Audio.source.audio)
                        Audio.source.audio.volume = v;
                }
            }
        }
        // live input level: talk and watch it move (only measured while this is open)
        Row {
            width: parent.width
            height: root.rowH
            spacing: Theme.u * 3
            PxIcon {
                name: micLevel.clipping ? "warn" : "mic"
                anchors.verticalCenter: parent.verticalCenter
                opacity: Audio.micMuted ? 0.4 : 1
            }
            PxLevelMeter {
                id: micLevel
                width: parent.width - Theme.u * 34
                anchors.verticalCenter: parent.verticalCenter
                node: Audio.source
                active: root.visible
                opacity: Audio.micMuted ? 0.4 : 1
            }
            PxText {
                width: Theme.u * 20
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                kind: "tiny"
                dim: !micLevel.clipping
                color: micLevel.clipping ? Theme.danger : Theme.textDim
                text: Audio.micMuted ? I18n.t("выкл", "muted") : micLevel.db > -90 ? Math.round(micLevel.db) + " dB" : "—"
            }
        }
        PxText {
            kind: "title"
            text: I18n.t("Приложения", "Applications") + (Audio.appStreams.length ? "  " + Audio.appStreams.length : "")
        }
    }

    // the programs: the rest of the window, scrolling when there are many
    PxBox {
        y: col.height + Theme.u * 3
        width: parent.width
        height: root.contentHeight - y
        sunken: true
        color: Theme.mix(Theme.sunken, Theme.face, 0.5)

        PxText {
            visible: Audio.appStreams.length === 0
            anchors.centerIn: parent
            text: I18n.t("сейчас ничего не звучит", "No audio is playing")
            dim: true
        }
        PxScroll {
            id: apps
            anchors.fill: parent
            anchors.margins: Theme.u * 3
            contentHeight: list.implicitHeight
            Column {
                id: list
                width: apps.flick.width
                spacing: Theme.u * 3
                Repeater {
                    model: Audio.appStreams
                    Column {
                        id: s
                        required property var modelData
                        width: list.width
                        spacing: Theme.u
                        PxText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: Audio.streamName(s.modelData)
                            dim: true
                        }
                        Row {
                            width: parent.width
                            height: root.rowH
                            spacing: Theme.u * 3
                            PxButton {
                                compact: true
                                anchors.verticalCenter: parent.verticalCenter
                                icon: s.modelData.audio && s.modelData.audio.muted ? "speakerMute" : "speaker"
                                onClicked: if (s.modelData.audio)
                                    s.modelData.audio.muted = !s.modelData.audio.muted
                            }
                            PxSlider {
                                width: parent.width - Theme.u * 20
                                anchors.verticalCenter: parent.verticalCenter
                                from: 0
                                to: 1.5
                                // a stream not bound yet reads 0: keep the slider still until it is
                                enabled: !!s.modelData.audio
                                value: s.modelData.audio ? s.modelData.audio.volume : 1
                                valueScale: 100
                                suffix: "%"
                                onMoved: v => {
                                    if (s.modelData.audio)
                                        s.modelData.audio.volume = v;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
