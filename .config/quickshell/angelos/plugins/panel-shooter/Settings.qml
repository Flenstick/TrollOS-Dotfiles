import QtQuick
import qs.config
import qs.widgets
import "."
import "Sprites.js" as Sprites

// Настройки → Плагины → Тир на панели
Column {
    id: root
    property var plugin
    width: parent ? parent.width : 400
    spacing: Theme.u * 5

    PxGroup {
        title: I18n.t("Тир на панели", "Panel shooter")
        icon: "gamepad"
        width: parent.width

        Row {
            spacing: Theme.u * 4
            PxIcon {
                bitmap: Sprites.RUN_A
                pixel: Theme.u * 3
                ink: "#2a1c14"
                fill: "#4f8ef7"
                fill2: "#2b3a67"
                fill3: "#f6d2b0"
            }
            PxIcon {
                anchors.bottom: parent.bottom
                bitmap: Sprites.GUN
                pixel: Theme.u * 3
                mirror: true
                ink: "#15161a"
                body: "#3d4049"
                light: "#9aa1ad"
            }
        }
        SettingRow {
            label: I18n.t("Случайные человечки", "Random people")
            hint: I18n.t("кроме друзей из Discord бегают ещё и случайные", "besides Discord friends, random people run too")
            PxToggle {
                checked: root.plugin ? root.plugin.get("randoms", false) : false
                onToggled: c => root.plugin.set("randoms", c)
            }
        }
        SettingRow {
            visible: root.plugin && root.plugin.get("randoms", false)
            label: I18n.t("Бегают и без пистолета", "Run even without the gun")
            hint: I18n.t("иногда пробегают по одному-двое", "now and then one or two run by")
            PxToggle {
                checked: root.plugin ? root.plugin.get("ambient", true) : true
                onToggled: c => root.plugin.set("ambient", c)
            }
        }
        SettingRow {
            visible: root.plugin && root.plugin.get("randoms", false) && root.plugin.get("ambient", true)
            label: I18n.t("Примерно раз в", "About every")
            PxSlider {
                width: parent.width
                from: 5
                to: 120
                stepSize: 5
                value: root.plugin ? root.plugin.get("ambientEvery", 15) : 15
                suffix: I18n.t(" с", " s")
                onReleased: v => root.plugin.set("ambientEvery", v)
            }
        }
        SettingRow {
            visible: root.plugin && root.plugin.get("randoms", false)
            label: I18n.t("Толпа с пистолетом", "Crowd while armed")
            hint: I18n.t("сколько человечков бегает одновременно", "how many people run at once")
            PxSlider {
                width: parent.width
                from: 1
                to: 15
                stepSize: 1
                value: root.plugin ? root.plugin.get("crowd", 5) : 5
                onReleased: v => root.plugin.set("crowd", v)
            }
        }
        SettingRow {
            label: I18n.t("Звук", "Sound")
            PxToggle {
                checked: root.plugin ? root.plugin.get("sound", true) : true
                onToggled: c => root.plugin.set("sound", c)
            }
        }
        SettingRow {
            label: I18n.t("Громкость", "Volume")
            PxSlider {
                width: parent.width
                from: 0
                to: 100
                stepSize: 5
                value: root.plugin ? Math.round(root.plugin.get("volume", 0.6) * 100) : 60
                suffix: "%"
                onReleased: v => root.plugin.set("volume", v / 100)
            }
        }
        SettingRow {
            label: I18n.t("Статистика", "Stats")
            hint: I18n.t("убито ", "kills ") + Gun.totalKills + I18n.t(", хедшотов ", ", headshots ") + Gun.totalHeadshots
            PxButton {
                danger: true
                icon: "trash"
                text: I18n.t("Сбросить", "Reset")
                onClicked: Gun.statsReset()
            }
        }
    }
}
