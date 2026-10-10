import QtQuick
import qs.config
import qs.widgets

// Остров, открытый перетаскиванием файла: большая зона «брось сюда».
Column {
    id: root

    property var phone
    property bool hovering: false
    readonly property int u: Theme.u
    readonly property bool ready: !!phone && phone.ready
    property string st: phone ? phone.state : "idle"     // IslandPopup отдаёт сюда состояние SendFx
    readonly property alias phoneItem: icon
    // чужая задача KDE (копирование и т. п.), пока телефону ничего не шлём
    readonly property var other: phone && st === "idle" && !hovering ? phone.otherJob : null
    readonly property bool transferring: !!phone && st === "sending" && phone.phoneJobCount > 0
    readonly property real barValue: other ? other.percent : transferring ? phone.progress : -1

    padding: Theme.pad
    spacing: u * 3

    PxBox {
        width: root.width - root.padding * 2
        height: root.u * 40
        sunken: true
        color: !root.ready ? Theme.sunken : root.st === "done" ? Theme.mix(Theme.sunken, Theme.ok, 0.25) : root.st === "error" ? Theme.mix(Theme.sunken, Theme.danger, 0.25) : root.hovering || root.st === "sending" ? Theme.mix(Theme.sunken, Theme.accent, 0.28) : Theme.sunken

        Behavior on color {
            ColorAnimation {
                duration: Theme.fast
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: root.u * 6

            PxIcon {
                visible: !!root.other
                name: "download"
                pixel: root.u * 2
                anchors.verticalCenter: parent.verticalCenter
            }
            PhoneIcon {
                id: icon
                visible: !root.other
                anchors.verticalCenter: parent.verticalCenter
                pixel: root.u * 2
                opacity: root.ready ? 1 : 0.5
                // телефон подпрыгивает, пока над ним держат файл
                SequentialAnimation on anchors.verticalCenterOffset {
                    running: root.hovering && root.ready
                    loops: Animation.Infinite
                    onRunningChanged: if (!running)
                        icon.anchors.verticalCenterOffset = 0
                    NumberAnimation {
                        to: -root.u * 2
                        duration: 220
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        to: 0
                        duration: 220
                        easing.type: Easing.InQuad
                    }
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.u * 2
                width: root.width - root.padding * 2 - icon.width - root.u * 18
                PxText {
                    width: parent.width
                    kind: "title"
                    wrapMode: Text.WordWrap
                    color: !root.ready || root.st === "error" ? Theme.danger : Theme.text
                    text: root.other ? (root.other.title || "Копирую…") : !root.ready ? "Телефон не на связи" : root.st === "sending" ? "Отправляю…" : root.st === "done" ? "Готово!" : root.st === "error" ? "Не вышло" : root.hovering ? "Отпускай!" : "Брось сюда"
                }
                PxText {
                    width: parent.width
                    dim: true
                    wrapMode: Text.WordWrap
                    elide: Text.ElideMiddle
                    maximumLineCount: 2
                    text: root.other ? root.other.file : !root.ready ? "Открой KDE Connect на телефоне" : root.st === "sending" ? (root.transferring ? root.phone.stateText : "летит на " + root.phone.name + "…") : root.st !== "idle" ? root.phone.stateText : "улетит на " + root.phone.name
                }
            }
        }
    }

    // ---- прогресс передачи + отмена ----
    Item {
        width: root.width - root.padding * 2
        height: root.u * 11
        visible: root.transferring || !!root.other

        PxBox {
            anchors.left: parent.left
            anchors.right: stop.left
            anchors.rightMargin: root.u * 3
            anchors.verticalCenter: parent.verticalCenter
            height: root.u * 6
            sunken: true
            color: Theme.sunken
            clip: true
            Rectangle {
                visible: root.barValue >= 0
                height: parent.height
                width: Math.round(parent.width * Math.max(0, root.barValue))
                color: Theme.accent
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
            // процент неизвестен — бегущий кусочек
            Rectangle {
                id: runner
                visible: root.barValue < 0
                height: parent.height
                width: parent.width / 4
                color: Theme.accent
                SequentialAnimation on x {
                    running: runner.visible
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: -runner.width
                        to: runner.parent ? runner.parent.width : 0
                        duration: 1100
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
        PxButton {
            id: stop
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            compact: true
            onClicked: root.phone.cancel()
        }
    }
}
