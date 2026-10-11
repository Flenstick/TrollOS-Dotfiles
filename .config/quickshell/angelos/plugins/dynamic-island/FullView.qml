pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Раскрытый остров: трек с обложкой и перемоткой, три строки текста, телефон.
Column {
    id: root

    property var host
    property bool active: false
    readonly property var phone: host ? host.phone : null
    readonly property var mirror: host ? host.mirror : null
    readonly property alias phoneItem: phoneIcon
    readonly property alias sendSource: buttons
    property string fxState: phone ? phone.state : "idle"   // состояние с учётом анимации (SendFx)
    // короткая подсказка в нижней строке (например, «Не беспокоить: вкл»)
    property string note: ""
    Timer {
        id: noteTimer
        interval: 2200
        onTriggered: root.note = ""
    }
    readonly property var player: Lyrics.player
    readonly property int u: Theme.u

    padding: Theme.pad
    spacing: u * 4

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
    property real pos: 0
    Timer {
        interval: 500
        running: root.active && !!root.player
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.player.positionChanged();
            root.pos = root.player.position;
        }
    }

    // ---- трек ----
    Item {
        width: root.width - root.padding * 2
        height: root.u * 28

        Art {
            id: art
            width: parent.height
            height: parent.height
            radius: 0
        }
        Column {
            anchors.left: art.right
            anchors.leftMargin: root.u * 5
            anchors.right: tools.left
            anchors.rightMargin: root.u * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.u * 2
            PxText {
                width: parent.width
                kind: "title"
                elide: Text.ElideRight
                text: Lyrics.title !== "" ? Lyrics.title : "Ничего не играет"
            }
            PxText {
                width: parent.width
                dim: true
                elide: Text.ElideRight
                text: Lyrics.artist !== "" ? Lyrics.artist : (root.player ? (root.player.identity || "") : "Включи музыку — тут появится трек")
            }
        }
        Row {
            id: tools
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: root.u * 2
            Equalizer {
                anchors.verticalCenter: parent.verticalCenter
                playing: Lyrics.playing
                visible: !!root.player
            }
            PxButton {
                icon: "gear"
                flat: true
                compact: true
                onClicked: {
                    root.host.close();
                    Shell.openSettings("lyrics");
                }
            }
        }
    }

    // ---- перемотка ----
    Column {
        width: root.width - root.padding * 2
        spacing: root.u * 2
        visible: !!root.player && Lyrics.length > 0

        // TrollOS: the progress as Android's wave while the track plays (Settings → Material You →
        // «Волна у трека»; it works in any look), flat while paused
        WavyLine {
            visible: Theme.materialSkin && Config.material.wavy
            width: parent.width
            height: root.u * 9
            progress: Math.min(1, root.pos / Math.max(1, Lyrics.length))
            playing: Lyrics.playing
            color: Theme.accent
            track: Qt.alpha(Theme.text, 0.22)
            MouseArea {
                anchors.fill: parent
                enabled: !!root.player && root.player.canSeek
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: m => {
                    root.player.position = Lyrics.length * Math.max(0, Math.min(1, m.x / width));
                    root.pos = root.player.position;
                }
            }
        }
        PxBox {
            visible: !(Theme.materialSkin && Config.material.wavy)
            width: parent.width
            height: root.u * 6
            sunken: true
            color: Theme.sunken
            Rectangle {
                height: parent.height
                width: Math.round(parent.width * Math.min(1, root.pos / Math.max(1, Lyrics.length)))
                color: Theme.accent
            }
            MouseArea {
                anchors.fill: parent
                enabled: !!root.player && root.player.canSeek
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: m => {
                    root.player.position = Lyrics.length * Math.max(0, Math.min(1, m.x / width));
                    root.pos = root.player.position;
                }
            }
        }
        Item {
            width: parent.width
            height: t0.height
            PxText {
                id: t0
                kind: "tiny"
                dim: true
                text: root.fmt(root.pos)
            }
            PxText {
                anchors.right: parent.right
                kind: "tiny"
                dim: true
                text: root.fmt(Lyrics.length)
            }
        }
    }

    // ---- кнопки ----
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.u * 3
        visible: !!root.player
        PxButton {
            icon: "prev"
            compact: true
            width: root.u * 22
            enabled: !!root.player && root.player.canGoPrevious
            onClicked: root.player.previous()
        }
        PxButton {
            icon: Lyrics.playing ? "pause" : "play"
            accent: true
            compact: true
            width: root.u * 30
            enabled: !!root.player && root.player.canTogglePlaying
            onClicked: root.player.togglePlaying()
        }
        PxButton {
            icon: "next"
            compact: true
            width: root.u * 22
            enabled: !!root.player && root.player.canGoNext
            onClicked: root.player.next()
        }
    }

    // ---- текст песни ----
    PxBox {
        width: root.width - root.padding * 2
        height: lyr.implicitHeight + root.u * 8
        visible: Lyrics.hasLyrics
        sunken: true
        color: Theme.sunken
        Column {
            id: lyr
            x: root.u * 5
            y: root.u * 4
            width: parent.width - root.u * 10
            spacing: root.u * 2
            PxText {
                width: parent.width
                dim: true
                elide: Text.ElideRight
                text: Lyrics.previous
                visible: text !== ""
            }
            PxText {
                width: parent.width
                wrapMode: Text.WordWrap
                color: Lyrics.playing ? Theme.text : Theme.textDim
                text: "<font color='" + Theme.hex(Theme.accent) + "'>♪</font> " + (Lyrics.current !== "" ? Lyrics.current : "~").replace(/&/g, "&amp;").replace(/</g, "&lt;")
                textFormat: Text.StyledText
            }
            PxText {
                width: parent.width
                dim: true
                elide: Text.ElideRight
                text: Lyrics.next
                visible: text !== ""
            }
        }
    }

    // ---- телефон ----
    Rectangle {
        width: root.width - root.padding * 2
        height: root.u
        color: Theme.lo
    }
    Item {
        width: root.width - root.padding * 2
        // as tall as its buttons (Material's are taller than the pixel ones)
        height: Math.max(root.u * 15, buttons.implicitHeight + root.u * 2)

        PhoneIcon {
            id: phoneIcon
            anchors.verticalCenter: parent.verticalCenter
            pixel: root.u
            opacity: root.phone && root.phone.reachable ? 1 : 0.5
        }
        Column {
            id: phoneLabels
            anchors.left: phoneIcon.right
            anchors.leftMargin: root.u * 4
            anchors.right: buttons.left
            anchors.rightMargin: root.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.u
            PxText {
                width: parent.width
                elide: Text.ElideRight
                text: root.phone && root.phone.name !== "" ? root.phone.name : "Телефон"
            }
            Row {
                spacing: root.u * 2
                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!root.phone && root.phone.reachable && root.phone.battery >= 0
                    level: root.phone ? root.phone.battery : -1
                    charging: !!root.phone && root.phone.charging
                }
                PxText {
                    kind: "tiny"
                    // never under the buttons: it elides instead
                    width: Math.min(implicitWidth, phoneLabels.width - x)
                    elide: Text.ElideRight
                    color: !root.phone || !root.phone.reachable ? Theme.danger : Theme.textDim
                    text: !root.phone || root.phone.deviceId === "" ? "KDE Connect не видит телефон" : !root.phone.reachable ? "не на связи" : root.phone.battery >= 0 ? root.phone.battery + "%" + (root.phone.charging ? " · заряжается" : "") : "на связи"
                }
            }
        }
        Row {
            id: buttons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.u * 2
            PxButton {
                enabled: !!root.phone && root.phone.ready
                icon: "folder"
                text: "Файл"
                compact: true
                onClicked: {
                    root.host.close();
                    root.phone.pickAndSend();
                }
            }
            PxButton {
                icon: "document"
                enabled: !!root.phone && root.phone.ready
                text: "Буфер"
                compact: true
                onClicked: root.phone.sendClipboard()
            }
            // экран телефона на компьютере (scrcpy по Wi-Fi)
            PxButton {
                enabled: !!root.phone && root.phone.ready || !!root.mirror && root.mirror.running
                icon: "monitor"
                text: root.mirror && root.mirror.running ? "Стоп" : "Экран"
                checked: !!root.mirror && (root.mirror.running || root.mirror.state !== "idle" && root.mirror.state !== "error")
                compact: true
                onClicked: root.mirror.toggle()
            }
            // «Не беспокоить»: уведомления не всплывают, тихо копятся в истории
            PxButton {
                icon: Config.notifications.dnd ? "bellOff" : "bell"
                checked: Config.notifications.dnd
                compact: true
                onClicked: {
                    Config.notifications.dnd = !Config.notifications.dnd;
                    root.note = Config.notifications.dnd ? "Не беспокоить: уведомления выключены" : "Уведомления снова включены";
                    noteTimer.restart();
                }
            }
        }
    }
    // ---- трансляция идёт: размер окна с телефоном ----
    Item {
        width: root.width - root.padding * 2
        height: root.u * 13
        visible: !!root.mirror && root.mirror.running

        PxIcon {
            id: monIcon
            name: "monitor"
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            anchors.left: monIcon.right
            anchors.leftMargin: root.u * 4
            anchors.right: sizeRow.left
            anchors.rightMargin: root.u * 2
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.mirror && root.mirror.winId < 0 ? "Открываю экран…" : root.mirror && root.mirror.full ? "Во весь экран" : "Размер экрана"
        }
        Row {
            id: sizeRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.u * 2
            enabled: !!root.mirror && root.mirror.winId >= 0 && root.mirror.ratio > 0
            PxButton {
                icon: root.mirror && root.mirror.audio ? "speaker" : "speakerMute"
                checked: !!root.mirror && root.mirror.audio
                compact: true
                onClicked: root.mirror.setAudio(!root.mirror.audio)
            }
            PxButton {
                icon: "minus"
                compact: true
                enabled: !!root.mirror && (root.mirror.full || root.mirror.winHeight > root.mirror.heights[0] + 8)
                onClicked: root.mirror.shrink()
            }
            PxButton {
                icon: "plus"
                compact: true
                enabled: !!root.mirror && (root.mirror.full || root.mirror.winHeight < root.mirror.heights[root.mirror.heights.length - 1] - 8)
                onClicked: root.mirror.grow()
            }
            PxButton {
                icon: "maximize"
                text: "Весь экран"
                compact: true
                checked: !!root.mirror && root.mirror.full
                onClicked: root.mirror.toggleFull()
            }
        }
    }
    // ---- трансляция экрана: подсказки и спаривание ----
    PxBox {
        id: mirrorBox
        readonly property string ms: root.mirror ? root.mirror.state : "idle"
        width: root.width - root.padding * 2
        height: mirrorCol.implicitHeight + root.u * 8
        visible: ms !== "idle" && ms !== "running"
        sunken: true
        color: ms === "error" ? Theme.mix(Theme.sunken, Theme.danger, 0.2) : Theme.sunken
        onVisibleChanged: if (visible && ms === "need-pair")
            codeField.input.forceActiveFocus()
        onMsChanged: if (ms === "need-pair")
            codeField.input.forceActiveFocus()

        Column {
            id: mirrorCol
            x: root.u * 5
            y: root.u * 4
            width: parent.width - root.u * 10
            spacing: root.u * 3

            Item {
                width: parent.width
                height: mHead.implicitHeight
                PxText {
                    id: mHead
                    anchors.left: parent.left
                    anchors.right: mClose.left
                    wrapMode: Text.WordWrap
                    color: mirrorBox.ms === "error" ? Theme.danger : Theme.text
                    text: mirrorBox.ms === "need-wifi" ? "Включи на телефоне отладку по Wi-Fi" : mirrorBox.ms === "need-pair" ? "Один раз спарь телефон с компьютером" : mirrorBox.ms === "error" ? "Трансляция не запустилась" : root.mirror ? root.mirror.message : ""
                }
                PxButton {
                    id: mClose
                    anchors.right: parent.right
                    icon: "close"
                    flat: true
                    compact: true
                    visible: !root.mirror || !root.mirror.busy
                    onClicked: root.mirror.dismiss()
                }
            }
            PxText {
                width: parent.width
                kind: "tiny"
                dim: true
                wrapMode: Text.WordWrap
                visible: text !== ""
                text: mirrorBox.ms === "need-wifi" ? "Настройки → Расширенные настройки → Для разработчиков → Отладка по Wi-Fi. Нет пункта «Для разработчиков»? В «О телефоне» 7 раз нажми на версию ОС." : mirrorBox.ms === "need-pair" ? "В «Отладке по Wi-Fi» нажми «Подключение с помощью кода» и введи сюда код из 6 цифр." : mirrorBox.ms === "error" ? (root.mirror ? root.mirror.message : "") : ""
            }
            PxText {
                width: parent.width
                kind: "tiny"
                wrapMode: Text.WordWrap
                color: Theme.danger
                visible: mirrorBox.ms === "need-pair" && !!root.mirror && root.mirror.message !== ""
                text: root.mirror ? root.mirror.message : ""
            }
            Row {
                spacing: root.u * 3
                visible: mirrorBox.ms === "need-pair"
                PxField {
                    id: codeField
                    width: root.u * 50
                    placeholder: "123456"
                    onAccepted: root.mirror.pair(text)
                }
                PxButton {
                    text: "Подключить"
                    accent: true
                    compact: true
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: codeField.text.replace(/\D/g, "").length === 6
                    onClicked: root.mirror.pair(codeField.text)
                }
            }
            PxButton {
                visible: mirrorBox.ms === "need-wifi" || mirrorBox.ms === "error"
                text: "Готово, проверить"
                accent: true
                compact: true
                onClicked: root.mirror.start()
            }
        }
    }
    // сколько я в войсе — тихо, в нижней строке вместо подсказки
    property real now: Date.now()
    Timer {
        interval: 15000
        running: root.active && !!root.host && !!root.host.voice
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }
    function voiceLine() {
        const v = host ? host.voice : null;
        if (!v)
            return "";
        const m = Math.max(0, Math.floor((now - v.since) / 60000));
        const t = m < 60 ? m + " мин" : Math.floor(m / 60) + " ч" + (m % 60 ? " " + m % 60 + " мин" : "");
        return "в войсе " + t + (v.channel ? " · " + v.channel : "");
    }
    PxText {
        width: root.width - root.padding * 2
        kind: "tiny"
        wrapMode: Text.WordWrap
        color: root.note !== "" ? Theme.text : root.fxState === "idle" ? Theme.textDim : root.fxState === "error" ? Theme.danger : root.fxState === "done" ? Theme.ok : Theme.text
        text: root.note !== "" ? root.note : root.fxState === "idle" ? (root.voiceLine() || "Перетащи файл на строку песни на панели — он улетит на телефон") : root.fxState === "sending" ? "Отправляю…" : root.phone.stateText
    }
}
