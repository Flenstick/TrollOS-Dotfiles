pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

// Bar icon: leaf / scales / lightning. Click — menu, wheel — switch modes.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    // TrollOS: the «Material You» skin — the mode as a symbol: a leaf, the balance, a bolt
    readonly property bool md: Theme.settingsSkinFor(root) === "material"
    MdSymbol {
        visible: root.md
        anchors.centerIn: parent
        z: 5
        name: PowerMode.current.id === "power-saver" ? "eco" : PowerMode.current.id === "performance" ? "bolt" : "balance"
        size: Theme.mdPx(22)
        fill: PowerMode.current.id === "balanced" ? 0 : 1
        color: PowerMode.current.id === "balanced" ? Theme.md.onSurfaceVariant : Theme.md.primary
    }
    implicitWidth: md ? Theme.mdPx(36) : icon.width + Theme.u * 4
    implicitHeight: Theme.u * 13

    // Смена режима — у каждого своя анимация (только когда режим правда сменился):
    //   энергосбережение  старый значок сжимается, лист падает сверху, покачиваясь, и мягко ложится
    //   баланс            весы выпрыгивают и качаются коромыслом, пока не уравновесятся
    //   производительность молния бьёт сверху: вспышка, дрожь, искры, неоновое мерцание
    // не привязки: иначе обновятся раньше обработчика смены режима
    property var shownBitmap: []
    property string lastId: ""
    Component.onCompleted: {
        shownBitmap = PowerMode.current.bitmap;
        lastId = PowerMode.current.id;
    }
    property bool ready: false
    property real fx: 0          // сдвиг, арт-пиксели
    property real fy: 0
    property real tilt: 0
    property real pop: 1
    property real fade: 1
    property real flash: 0
    property real sparks: 0
    property string kind: ""
    Timer {
        interval: 2500
        running: true
        onTriggered: root.ready = true
    }
    Connections {
        target: PowerMode
        function onCurrentChanged() {
            const id = PowerMode.current.id;
            if (id === root.lastId)
                return;
            root.lastId = id;
            if (!root.ready || Motion.ms(100) === 0) {
                root.shownBitmap = PowerMode.current.bitmap;
                return;
            }
            root.kind = id;
            fxAnim.restart();
        }
    }

    Item {
        id: holder
        anchors.centerIn: parent
        width: icon.width
        height: icon.height
        opacity: (mouse.containsMouse || popup.visible ? 1 : 0.8) * root.fade
        transform: Translate {
            x: Math.round(root.fx) * Theme.u
            y: Math.round(root.fy) * Theme.u
        }
        PxIcon {
            id: icon
            opacity: root.md ? 0 : 1
            pixel: Theme.u
            bitmap: Array.from(root.shownBitmap)
            scale: root.pop
            rotation: root.tilt
            transformOrigin: root.kind === "balanced" ? Item.Top : root.kind === "power-saver" ? Item.Top : Item.Center
            smooth: Math.abs(root.tilt) > 0.5
            // вспышка: тот же значок, залитый светом
            PxIcon {
                anchors.fill: parent
                pixel: Theme.u
                bitmap: parent.bitmap
                visible: root.flash > 0.01
                opacity: root.flash
                ink: "#ffffff"
                fill: "#ffffff"
                fill2: "#ffffff"
                fill3: "#fff3c0"
                light: "#ffffff"
            }
        }
        // искры молнии
        Repeater {
            model: 8
            Rectangle {
                required property int index
                readonly property real a: index / 8 * Math.PI * 2 + 0.4
                readonly property real d: (3 + root.sparks * 7 + (index % 3)) * Theme.u
                visible: root.sparks > 0 && root.sparks < 1
                width: Theme.u
                height: Theme.u
                color: index % 2 ? Theme.accent2 : "#fff3c0"
                opacity: 1 - root.sparks
                x: icon.width / 2 + Math.cos(a) * d - width / 2
                y: icon.height / 2 + Math.sin(a) * d * 0.7 - height / 2
            }
        }
    }

    SequentialAnimation {
        id: fxAnim
        // старый значок уходит
        ParallelAnimation {
            NumberAnimation { target: root; property: "pop"; to: 0.4; duration: 110; easing.type: Easing.InBack }
            NumberAnimation { target: root; property: "fade"; to: 0; duration: 110 }
        }
        ScriptAction {
            script: {
                root.shownBitmap = PowerMode.current.bitmap;
                root.tilt = 0;
                root.flash = 0;
                root.sparks = 0;
                root.fx = 0;
                if (root.kind === "power-saver") {
                    root.fy = -8; root.pop = 1; root.fade = 0; saver.restart();
                } else if (root.kind === "balanced") {
                    root.fy = 0; root.pop = 0; root.fade = 1; balanced.restart();
                } else {
                    root.fy = -10; root.pop = 1; root.fade = 1; bolt.restart();
                }
            }
        }
    }

    // лист падает: качается из стороны в сторону, приземляется мягко
    ParallelAnimation {
        id: saver
        NumberAnimation { target: root; property: "fade"; to: 1; duration: 160 }
        NumberAnimation { target: root; property: "fy"; to: 0; duration: 900; easing.type: Easing.OutQuad }
        SequentialAnimation {
            NumberAnimation { target: root; property: "fx"; to: -3; duration: 220; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "fx"; to: 2.5; duration: 260; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "fx"; to: -1.5; duration: 220; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "fx"; to: 0; duration: 200; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            NumberAnimation { target: root; property: "tilt"; to: -22; duration: 220; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "tilt"; to: 18; duration: 260; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "tilt"; to: -9; duration: 220; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "tilt"; to: 0; duration: 200; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "pop"; to: 0.88; duration: 70 }
            NumberAnimation { target: root; property: "pop"; to: 1; duration: 200; easing.type: Easing.OutBack }
        }
    }

    // весы: выпрыгнули и ищут равновесие
    SequentialAnimation {
        id: balanced
        NumberAnimation { target: root; property: "pop"; to: 1; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
        NumberAnimation { target: root; property: "tilt"; to: 16; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "tilt"; to: -12; duration: 240; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "tilt"; to: 7; duration: 220; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "tilt"; to: -3; duration: 200; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "tilt"; to: 0; duration: 180; easing.type: Easing.InOutSine }
    }

    // молния: удар, вспышка, дрожь, искры, неон моргает
    SequentialAnimation {
        id: bolt
        NumberAnimation { target: root; property: "fy"; to: 0; duration: 90; easing.type: Easing.InQuad }
        ParallelAnimation {
            NumberAnimation { target: root; property: "flash"; from: 1; to: 0; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "sparks"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: root; property: "pop"; to: 1.3; duration: 60; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "pop"; to: 1; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 3 }
            }
            SequentialAnimation {
                loops: 3
                PropertyAction { target: root; property: "fx"; value: 1 }
                PauseAnimation { duration: 40 }
                PropertyAction { target: root; property: "fx"; value: -1 }
                PauseAnimation { duration: 40 }
                PropertyAction { target: root; property: "fx"; value: 0 }
                PauseAnimation { duration: 30 }
            }
        }
        PauseAnimation { duration: 120 }
        PropertyAction { target: root; property: "fade"; value: 0.35 }
        PauseAnimation { duration: 60 }
        PropertyAction { target: root; property: "fade"; value: 1 }
        PauseAnimation { duration: 90 }
        PropertyAction { target: root; property: "fade"; value: 0.5 }
        PauseAnimation { duration: 50 }
        PropertyAction { target: root; property: "fade"; value: 1 }
        NumberAnimation { target: root; property: "flash"; from: 0.6; to: 0; duration: 200 }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: e => e.button === Qt.MiddleButton ? PowerMode.cycle() : popup.toggle()
        onWheel: w => PowerMode.step(w.angleDelta.y > 0 ? 1 : -1)
    }

    Connections {
        target: PowerMode
        function onMenuRequested() {
            popup.toggle();
        }
    }

    BarPopup {
        id: popup
        panelId: "power-mode"
        anchorItem: root
        above: Config.bar.style === "taskbar"
        title: "power.exe"
        icon: "power"
        contentWidth: Theme.u * 130
        contentHeight: list.implicitHeight

        Column {
            id: list
            width: parent.width
            spacing: Theme.u * 2

            Repeater {
                // by index: a Repeater would turn the bitmap rows into a QStringList, which PxIcon can't draw
                model: PowerMode.available.length
                PxButton {
                    id: row
                    required property int index
                    readonly property var modelData: PowerMode.available[index]
                    width: list.width
                    height: Theme.u * 20
                    checked: PowerMode.current.id === modelData.id
                    onClicked: PowerMode.set(modelData.id)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.u * 5
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 5
                        Item {
                            width: Theme.u * 11
                            height: Theme.u * 10
                            anchors.verticalCenter: parent.verticalCenter
                            PxIcon {
                                anchors.centerIn: parent
                                bitmap: row.modelData.bitmap
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            PxText {
                                text: row.modelData.name
                            }
                            PxText {
                                kind: "tiny"
                                dim: true
                                text: row.modelData.hint
                            }
                        }
                    }
                }
            }
            PxText {
                visible: PowerMode.degraded !== ""
                width: list.width
                wrapMode: Text.Wrap
                kind: "tiny"
                dim: true
                text: "⚠ производительность урезана: " + PowerMode.degraded
            }
        }
    }
}
