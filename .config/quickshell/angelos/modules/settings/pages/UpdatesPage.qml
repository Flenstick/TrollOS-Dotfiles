pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Updates for everyone: check the dotfiles repository and apply new versions.
PxPage {
    id: page

    heading: I18n.t("Обновления", "Updates")
    subtitle: I18n.t("TrollOS обновляется из репозитория, из которого его установили. Меняются только файлы, которые изменились в обновлении; твои правки сливаются с новой версией, а если не получилось — твой файл остаётся, новая версия ложится рядом (*.trollos-new). Перед обновлением снимок конфигов — обновление можно откатить.", "TrollOS updates from the repository it was installed from. Only files the update changed are touched; your edits are merged with the new version, and when that fails your file stays and the new one is put next to it (*.trollos-new). Your configs are snapshotted first, so an update can be rolled back.")

    Component.onCompleted: {
        Updates.find();
        Updates.readLast();
        Updates.checkUpstream();
        if (Updates.repo && Updates.state === "idle")
            Updates.check();
    }

    PxGroup {
        title: I18n.t("Состояние", "Status")
        icon: "download"
        width: parent.width

        // no repository yet: offer the official one
        Column {
            visible: !Updates.repo
            width: parent.width
            spacing: Theme.u * 4
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: I18n.t("Репозиторий dotfiles не найден. Скачать официальный в ~/.local/share/angelos/dotfiles, чтобы получать обновления?", "No dotfiles repository found. Download the official one to ~/.local/share/angelos/dotfiles to receive updates?")
            }
            PxButton {
                icon: "download"
                accent: true
                enabled: !Updates.busy
                text: Updates.state === "cloning" ? I18n.t("скачиваю…", "downloading…") : I18n.t("Скачать dotfiles", "Download dotfiles")
                onClicked: Updates.clone()
            }
        }

        SettingRow {
            visible: !!Updates.repo
            label: I18n.t("Репозиторий", "Repository")
            hint: Updates.remote
            PxText {
                width: parent.width
                elide: Text.ElideMiddle
                text: Updates.repo + (Updates.branch ? "  ·  " + Updates.branch : "")
            }
        }
        SettingRow {
            visible: !!Updates.repo
            label: I18n.t("Новое", "New")
            hint: Config.updates.lastCheck ? I18n.t("проверено ", "checked ") + new Date(Config.updates.lastCheck).toLocaleString(Qt.locale(), "dd.MM HH:mm") : ""
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                color: Updates.available ? Theme.accent : Theme.textDim
                text: Updates.state === "checking" ? I18n.t("проверяю…", "checking…") : Updates.error ? "✕ " + Updates.error : Updates.available ? I18n.t("доступно изменений: ", "changes available: ") + Updates.behind : I18n.t("у тебя последняя версия ♡", "you are up to date ♡")
            }
        }
        PxText {
            visible: !Updates.trusted && !!Updates.repo
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: I18n.t("origin репозитория указывает не на официальный репозиторий и не на тот, из которого ставилась система — обновление отключено.", "The repository origin is neither the official one nor the one this system was installed from — updating is disabled.")
        }
        PxText {
            visible: Updates.dirty > 0
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.accent3
            text: I18n.t("В папке репозитория есть свои правки (" + Updates.dirty + "). Обновление остановится, чтобы их не потерять.", "The repository folder has local edits (" + Updates.dirty + "). The update stops so they are not lost.")
        }
        Flow {
            visible: !!Updates.repo
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                icon: "refresh"
                text: I18n.t("Проверить", "Check")
                enabled: !Updates.busy
                onClicked: Updates.check()
            }
            PxButton {
                icon: "download"
                accent: Updates.available
                enabled: !Updates.busy && Updates.dirty === 0 && Updates.trusted
                text: Updates.state === "updating" ? I18n.t("обновляю…", "updating…") : I18n.t("Обновить", "Update")
                onClicked: Updates.update()
            }
            PxButton {
                visible: Updates.canRollback
                icon: "arrowLeft"
                enabled: !Updates.busy
                text: Updates.state === "rollingback" ? I18n.t("откатываю…", "rolling back…") : I18n.t("Откатить обновление", "Roll back the update")
                onClicked: Updates.rollback()
            }
            PxButton {
                visible: Updates.state === "done"
                icon: "power"
                text: I18n.t("Перезапустить оболочку", "Restart the shell")
                onClicked: Updates.restartShell()
            }
        }
        SettingRow {
            visible: Updates.canRollback
            label: I18n.t("Последнее обновление", "Last update")
            hint: I18n.t("откат вернёт конфиги из снимка, а то, что сейчас, сохранит отдельно", "rolling back puts the snapshot's configs back and keeps the current ones aside")
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: Updates.last ? Updates.last.when.replace(/^(\d{4})(\d\d)(\d\d)-(\d\d)(\d\d).*/, "$3.$2.$1 $4:$5") + "  ·  " + Updates.last.from + " → " + Updates.last.to : ""
            }
        }
        SettingRow {
            label: I18n.t("Проверять раз в день", "Check once a day")
            hint: I18n.t("только уведомление, ставится по кнопке", "only a notification; installing is up to you")
            PxToggle {
                checked: Config.updates.autoCheck
                onToggled: c => Config.updates.autoCheck = c
            }
        }
    }

    // TrollOS: the original angelOS (the author's repository has it as "upstream")
    PxGroup {
        visible: Updates.hasUpstream
        title: I18n.t("angelOS (оригинал)", "angelOS (the original)")
        icon: "sparkle"
        width: parent.width
        SettingRow {
            label: I18n.t("Новое у MixaDoDs", "New from MixaDoDs")
            hint: "github.com/MixaDoDs/AngelOS-Dotfiles"
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                color: Updates.upstreamBehind ? Theme.accent : Theme.textDim
                text: Updates.upstreamChecking ? I18n.t("проверяю…", "checking…") : Updates.upstreamBehind ? I18n.t("изменений: ", "changes: ") + Updates.upstreamBehind : I18n.t("всё уже влито ♡", "all merged ♡")
            }
        }
        PxText {
            visible: Updates.upstreamBehind > 0
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: I18n.t("Сами они не ставятся: кнопка «Обновить» вернула бы ангела вместо TrollOS. Влить — scripts/trollos/upstream.sh merge в ~/Projects/TrollOS-Dotfiles (конфликты решаются руками).", "They are not installed by themselves: «Update» would bring the angel back. To merge: scripts/trollos/upstream.sh merge in ~/Projects/TrollOS-Dotfiles (conflicts by hand).")
        }
        Repeater {
            model: Updates.upstreamIncoming.slice(0, 12)
            PxText {
                required property string modelData
                width: parent.width
                elide: Text.ElideRight
                kind: "tiny"
                text: "✧ " + modelData.replace(/^\S+\s/, "")
            }
        }
        PxText {
            visible: Updates.upstreamIncoming.length > 12
            text: I18n.t("…и ещё ", "…and ") + (Updates.upstreamBehind - 12)
            kind: "tiny"
            dim: true
        }
        PxButton {
            icon: "refresh"
            text: I18n.t("Проверить angelOS", "Check angelOS")
            enabled: !Updates.upstreamChecking
            onClicked: Updates.checkUpstream()
        }
    }

    PxGroup {
        visible: Updates.conflicts.length > 0
        title: I18n.t("Твои правки сохранены", "Your edits were kept")
        icon: "warn"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("В этих файлах и ты, и обновление поменяли одни и те же строки. Оставлен твой вариант, новый лежит рядом с окончанием .trollos-new — сравни и перенеси, что нужно.", "You and the update changed the same lines in these files. Yours stayed; the new one is next to it ending in .trollos-new — compare and take what you need.")
        }
        Repeater {
            model: Updates.conflicts
            PxText {
                required property string modelData
                width: parent.width
                kind: "mono"
                elide: Text.ElideMiddle
                text: "✧ " + modelData.replace(Config.home, "~")
            }
        }
    }

    PxGroup {
        visible: Updates.incoming.length > 0
        title: I18n.t("Что нового", "What's new")
        icon: "sparkle"
        width: parent.width
        Repeater {
            model: Updates.incoming
            PxText {
                required property string modelData
                width: parent.width
                elide: Text.ElideRight
                text: "✧ " + modelData.replace(/^\S+\s/, "")
            }
        }
    }

    PxGroup {
        visible: Updates.log.length > 0
        title: I18n.t("Журнал", "Log")
        icon: "terminal"
        width: parent.width
        PxBox {
            width: parent.width
            height: Theme.u * 110
            sunken: true
            color: Theme.sunken
            PxScroll {
                id: logScroll
                anchors.fill: parent
                anchors.margins: Theme.u * 3
                contentHeight: logText.implicitHeight
                PxText {
                    id: logText
                    width: logScroll.width - Theme.u * 6
                    kind: "mono"
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                    text: Updates.log.join("\n")
                    onTextChanged: Qt.callLater(() => logScroll.contentY = Math.max(0, logScroll.contentHeight - logScroll.height))
                }
            }
        }
    }
}
