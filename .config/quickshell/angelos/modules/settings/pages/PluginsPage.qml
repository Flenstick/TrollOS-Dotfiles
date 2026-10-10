pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import "../../../widgets/MacIcons.js" as MacIcons

// Community Plugins — angelOS's one place for plugins (services/CommunityPlugins): everything
// installed (bundled, from the community catalog, your own) next to the approved entries of
// the registry. Install, switch on and off, update, remove; the removed ones and a new plugin
// below. The launcher's "plugins …" does the same (plugins/community, a core plugin).
PxPage {
    id: page

    heading: I18n.t("Плагины · Community", "Plugins · Community")
    subtitle: I18n.t("Один каталог: встроенные плагины, плагины сообщества и твои собственные. Установка, включение, обновление и удаление — здесь. Плагин — папка ~/.config/angelos/plugins/<id>/ с manifest.json (docs/PLUGINS.md).", "One catalog: bundled plugins, community plugins and your own. Install, enable, update and remove them here. A plugin is a folder ~/.config/angelos/plugins/<id>/ with manifest.json (docs/PLUGINS.md).")

    property string createLog: ""
    property string removeLog: ""
    property string confirmId: ""           // the card whose bin was clicked once ("details:<id>" — its details open)
    property string confirmUpdateId: ""
    property string openId: ""              // TrollOS: the plugin row that is opened
    property string search: ""
    property string filter: "all"           // all | installed | updates | available
    readonly property var updateIds: CommunityPlugins.updates.map(e => e.id)
    function matches(o) {
        const q = search.trim().toLowerCase();
        if (!q)
            return true;
        return [I18n.label(o.name), o.id, o.author || "", I18n.label(o.description || ""), o.category || "", ...(o.tags || [])].join(" ").toLowerCase().includes(q);
    }
    // installed ones (with their catalog entry, if any), then the catalog's not installed ones
    readonly property var installedShown: (filter === "available" ? [] : Plugins.plugins).filter(p => matches(p) && (filter !== "updates" || updateIds.includes(p.id)))
    readonly property var availableShown: (filter === "all" || filter === "available" ? CommunityPlugins.entries : []).filter(e => !CommunityPlugins.installed(e.id) && matches(e))
    function capabilities(p) {
        return [p.menu ? I18n.t("ПКМ-меню", "menu") : "", p.menuComponent ? I18n.t("меню (QML)", "menu (QML)") : "", p.barWidget ? I18n.t("панель", "bar") : "", p.desktopWidget ? I18n.t("рабочий стол", "desktop") : "", p.launcher ? I18n.t("лаунчер", "launcher") : "", p.main ? I18n.t("сервис", "service") : "", p.settings ? I18n.t("настройки", "settings") : ""].filter(s => s).join(" · ");
    }
    function originText(p) {
        if (Plugins.isCore(p))
            return I18n.t("часть angelOS", "part of angelOS");
        const o = CommunityPlugins.origin(p);
        return o === "bundled" ? I18n.t("встроенный", "bundled") : o === "community" ? I18n.t("из каталога", "from the catalog") : I18n.t("свой", "your own");
    }
    Component.onCompleted: if (Quickshell.env("ANGELOS_TEST") !== "1" && !CommunityPlugins.entries.length) CommunityPlugins.refresh()
    Timer {
        id: confirmReset
        interval: 4000
        onTriggered: {
            page.confirmId = "";
            page.confirmUpdateId = "";
        }
    }
    PxButton {
        visible: Config.developer.enabled
        text: I18n.t("Создать плагин с ИИ", "Create a plugin with AI")
        icon: "sparkle"
        accent: true
        onClicked: Shell.settingsGo(page, "studio")
    }
    Connections {
        target: Plugins
        function onMoveFailed(why) {
            page.removeLog = why;
        }
        function onCreated(id, ok) {
            page.createLog = ok ? I18n.t("создан ~/.config/angelos/plugins/", "Created ~/.config/angelos/plugins/") + id + " ♡" : I18n.t("не получилось (такая папка уже есть?)", "Could not create plugin. Does the folder already exist?");
        }
    }

    PxGroup {
        name: "community"
        title: I18n.t("Каталог", "Catalog")
        icon: "package"
        width: parent.width

        // TrollOS: search and the filters in one row, the actions in another, the fine print short
        Item {
            width: parent.width
            height: Math.max(searchField.height, filterRow.height)
            PxField {
                id: searchField
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(Theme.u * 80, parent.width - filterRow.width - Theme.u * 4)
                icon: "search"
                placeholder: I18n.t("Найти плагин", "Find a plugin")
                text: page.search
                onEdited: page.search = text
            }
            Row {
                id: filterRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.u * 2
                Repeater {
                    model: [
                        {key: "all", ru: "Все", en: "All"},
                        {key: "installed", ru: "Установленные", en: "Installed"},
                        {key: "updates", ru: "Обновления", en: "Updates"},
                        {key: "available", ru: "Каталог", en: "Catalog"}
                    ]
                    PxButton {
                        required property var modelData
                        compact: true
                        text: I18n.label({ru: modelData.ru, en: modelData.en}) + (modelData.key === "updates" && page.updateIds.length ? " (" + page.updateIds.length + ")" : "")
                        checked: page.filter === modelData.key
                        onClicked: page.filter = modelData.key
                    }
                }
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: "refresh"
                text: I18n.t("Проверить обновления", "Check for updates")
                enabled: !CommunityPlugins.busy
                onClicked: CommunityPlugins.refresh()
            }
            PxButton {
                visible: page.updateIds.length > 0
                compact: true
                accent: true
                icon: "download"
                text: I18n.t("Обновить все (", "Update all (") + page.updateIds.length + ")"
                enabled: !CommunityPlugins.busy
                onClicked: CommunityPlugins.updateAll()
            }
            PxToggle {
                text: I18n.t("проверять раз в день", "check once a day")
                checked: Config.plugins.autoCheck
                onToggled: v => Config.plugins.autoCheck = v
            }
            PxButton {
                compact: true
                icon: "external"
                text: I18n.t("Опубликовать", "Publish")
                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/futureUnd1ground/angelos-community-registry/blob/main/CONTRIBUTING.md"])
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            kind: "tiny"
            dim: true
            text: (CommunityPlugins.entries.length ? I18n.t("В каталоге ", "In the catalog: ") + CommunityPlugins.entries.length + (Config.plugins.lastCheck ? I18n.t(", проверено ", ", checked ") + new Date(Config.plugins.lastCheck).toLocaleString(Qt.locale(), "d MMM HH:mm") : "") + ". " : "") + I18n.t("Только одобренные плагины; они работают с твоими правами, а при неудачном обновлении сама вернётся прежняя версия.", "Approved plugins only; they run with your permissions, and a failed update puts the old version back by itself.")
        }
        PxText {
            visible: CommunityPlugins.busy
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: CommunityPlugins.action === "fetch" ? I18n.t("Загружаю каталог…", "Loading the catalog…")
                : CommunityPlugins.action === "rollback" ? I18n.t("Возвращаю прежнюю версию…", "Putting the earlier version back…")
                : (CommunityPlugins.action === "update" ? I18n.t("Обновляю ", "Updating ") : I18n.t("Устанавливаю ", "Installing ")) + CommunityPlugins.busyId + (CommunityPlugins.queue.length ? I18n.t(" · ещё в очереди: ", " · still queued: ") + CommunityPlugins.queue.length : "") + "…"
        }
        PxText {
            visible: CommunityPlugins.error !== ""
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: CommunityPlugins.error
        }
        PxText {
            visible: CommunityPlugins.message !== "" && !CommunityPlugins.busy
            width: parent.width
            wrapMode: Text.Wrap
            text: CommunityPlugins.message + " ♡"
        }
    }

    PxGroup {
        name: "installed"
        visible: page.filter !== "available"
        title: (page.filter === "updates" ? I18n.t("Обновления (", "Updates (") : I18n.t("Установленные (", "Installed (")) + page.installedShown.length + ")"
        icon: "plug"
        width: parent.width

        PxText {
            visible: page.installedShown.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: page.filter === "updates" ? I18n.t("Все плагины свежие.", "Every plugin is up to date.") : I18n.t("Ничего не найдено.", "Nothing found.")
        }
        Repeater {
            model: page.installedShown
            // a card: the pixel box, or a rounded group in the Mac look (SkinCard, the Theme API)
            // TrollOS: one row per plugin — icon, name, one line about it, ⚙ and the switch on the
            // right; a click opens the rest (the whole description, what it adds, the buttons with words)
            SkinCard {
                id: card
                required property var modelData
                padding: 0
                group: true
                readonly property bool on: Plugins.isEnabled(modelData)
                readonly property bool core: Plugins.isCore(modelData)
                readonly property var entry: CommunityPlugins.entry(modelData.id)
                readonly property bool canUpdate: page.updateIds.includes(modelData.id)
                readonly property bool open: page.openId === modelData.id
                readonly property bool failed: CommunityPlugins.failed.includes(modelData.id)
                readonly property string warning: Plugins.themeWarning(modelData)
                width: parent.width
                height: head.height + (open ? more.implicitHeight + Theme.u * 4 : 0) + Theme.u * 4
                pixelColor: rowMouse.containsMouse && !open ? Theme.mix(Theme.face, Theme.accent, 0.12) : on ? Theme.mix(Theme.face, Theme.accent, 0.06) : Theme.face
                opacity: on || core ? 1 : 0.75

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.openId = card.open ? "" : card.modelData.id
                }

                Item {
                    id: head
                    x: Theme.u * 4
                    y: Theme.u * 2
                    width: parent.width - Theme.u * 8
                    height: Math.max(Theme.u * 16, headText.implicitHeight)
                    // its icon: the pixel one, a line icon in the Mac look
                    Item {
                        id: cardIcon
                        readonly property bool mac: Skin.mac && !Skin.hell
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.u * 14
                        height: Theme.u * 14
                        PxIcon {
                            visible: !cardIcon.mac
                            anchors.centerIn: parent
                            name: card.modelData.icon || "plug"
                        }
                        MacIcon {
                            visible: cardIcon.mac
                            anchors.centerIn: parent
                            name: MacIcons.fromPixel(card.modelData.icon || "") || "puzzle"
                            size: GoldenGate.px(20)
                            color: Theme.accent
                        }
                    }
                    Column {
                        id: headText
                        anchors.left: cardIcon.right
                        anchors.leftMargin: Theme.u * 4
                        anchors.right: side.left
                        anchors.rightMargin: Theme.u * 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u / 2
                        Row {
                            width: parent.width
                            spacing: Theme.u * 3
                            PxText {
                                text: I18n.label(card.modelData.name)
                                font.bold: true
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, parent.width - tags.width - parent.spacing)
                            }
                            PxText {
                                id: tags
                                anchors.verticalCenter: parent.verticalCenter
                                kind: "tiny"
                                color: card.canUpdate || card.failed || card.warning ? Theme.accent : Theme.textDim
                                text: card.canUpdate ? I18n.t("есть обновление", "update available") : card.failed ? I18n.t("обновление не загрузилось", "the update failed") : card.warning ? I18n.t("не для этой темы", "not for this theme") : page.originText(card.modelData)
                            }
                        }
                        PxText {
                            width: parent.width
                            text: I18n.label(card.modelData.description || "")
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            kind: "tiny"
                            dim: true
                            visible: !card.open && text !== ""
                        }
                    }
                    Row {
                        id: side
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 3
                        PxButton {
                            visible: !!card.modelData.settings && card.on
                            anchors.verticalCenter: parent.verticalCenter
                            compact: true
                            icon: "gear"
                            onClicked: page.nav.settingsPage = "plugin:" + card.modelData.id
                        }
                        PxToggle {
                            visible: !card.core
                            anchors.verticalCenter: parent.verticalCenter
                            checked: card.on
                            onToggled: c => Plugins.setEnabled(card.modelData.id, c)
                        }
                        PxText {
                            visible: card.core
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.t("всегда вкл.", "always on")
                            kind: "tiny"
                            dim: true
                        }
                    }
                }

                // ---- opened: everything else ----
                Column {
                    id: more
                    visible: card.open
                    x: head.x + cardIcon.width + Theme.u * 4
                    y: head.y + head.height + Theme.u * 2
                    width: head.width - cardIcon.width - Theme.u * 4
                    spacing: Theme.u * 2
                    PxText {
                        width: parent.width
                        text: I18n.label(card.modelData.description || "")
                        wrapMode: Text.Wrap
                        dim: true
                    }
                    PluginThemeBadge {
                        plugin: card.modelData
                    }
                    PxText {
                        visible: card.warning !== ""
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: card.warning
                        color: Theme.danger
                        kind: "tiny"
                    }
                    PxText {
                        visible: card.canUpdate
                        text: I18n.t("Доступна версия ", "Version available: ") + (card.entry ? card.entry.version : "")
                        color: Theme.accent
                        kind: "tiny"
                    }
                    PxText {
                        visible: card.failed
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: I18n.t("Последнее обновление не загрузилось — оставлена прежняя версия", "The last update did not load — the earlier version stays")
                        color: Theme.danger
                        kind: "tiny"
                    }
                    PxText {
                        width: parent.width
                        wrapMode: Text.Wrap
                        kind: "tiny"
                        dim: true
                        text: "v" + (card.modelData.version || "0") + "  ·  " + page.originText(card.modelData) + (page.capabilities(card.modelData) ? "  ·  " + page.capabilities(card.modelData) : "") + (card.modelData.author ? "  ·  " + card.modelData.author : "")
                    }
                    Flow {
                        width: parent.width
                        spacing: Theme.u * 2
                        PxButton {
                            visible: card.canUpdate
                            compact: true
                            accent: true
                            icon: "download"
                            text: page.confirmUpdateId === card.modelData.id ? I18n.t("Точно?", "Sure?") : I18n.t("Обновить", "Update")
                            enabled: !CommunityPlugins.busy
                            onClicked: {
                                if (page.confirmUpdateId !== card.modelData.id) {
                                    page.confirmUpdateId = card.modelData.id;
                                    confirmReset.restart();
                                    return;
                                }
                                page.confirmUpdateId = "";
                                CommunityPlugins.update(card.modelData.id);
                            }
                        }
                        PxButton {
                            visible: !!card.modelData.settings && card.on
                            compact: true
                            icon: "gear"
                            text: I18n.t("Настройки", "Settings")
                            onClicked: page.nav.settingsPage = "plugin:" + card.modelData.id
                        }
                        PxButton {
                            compact: true
                            icon: "folder"
                            text: I18n.t("Папка", "Folder")
                            onClicked: Shell.openPath(card.modelData.dir)
                        }
                        PxButton {
                            visible: !!card.entry && !!card.entry.repository
                            compact: true
                            icon: "external"
                            text: I18n.t("Исходники", "Source")
                            onClicked: Quickshell.execDetached(["xdg-open", card.entry.repository])
                        }
                        // your own plugins: load the files again, or improve them in Plugin Studio
                        PxButton {
                            visible: !card.modelData.bundled
                            compact: true
                            icon: "refresh"
                            text: I18n.t("Перезагрузить", "Reload")
                            enabled: !PluginStudio.busy
                            onClicked: PluginStudio.reloadPlugin(card.modelData.id)
                        }
                        PxButton {
                            visible: !card.modelData.bundled && Config.developer.enabled
                            compact: true
                            icon: "sparkle"
                            text: I18n.t("Доработать", "Improve")
                            onClicked: {
                                PluginStudio.editRequest = card.modelData.id;
                                Shell.settingsGo(page, "studio");
                            }
                        }
                        // its desktop widget only knows heaven: Studio draws its hell (offered while the demon rules)
                        PxButton {
                            visible: Angel.hellShown && Config.developer.enabled && PluginStudio.needsHell(card.modelData)
                            compact: true
                            icon: "fire"
                            text: I18n.t("Адская версия", "Hell version")
                            enabled: !PluginStudio.busy
                            onClicked: {
                                PluginStudio.hellRequest = card.modelData.id;
                                PluginStudio.editRequest = card.modelData.id;
                                Shell.settingsGo(page, "studio");
                            }
                        }
                        // remove (a second click confirms): yours go to the trash, bundled ones hide;
                        // angelOS's own part (core) stays
                        PxButton {
                            readonly property bool asking: page.confirmId === card.modelData.id
                            visible: !card.core
                            compact: true
                            danger: true
                            icon: "trash"
                            text: asking ? I18n.t("Точно удалить?", "Remove for sure?") : I18n.t("Удалить", "Remove")
                            checked: asking
                            onClicked: {
                                if (!asking) {
                                    page.confirmId = card.modelData.id;
                                    confirmReset.restart();
                                    return;
                                }
                                page.confirmId = "";
                                page.removeLog = "";
                                Plugins.remove(card.modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }

    PxGroup {
        name: "available"
        visible: page.filter === "all" || page.filter === "available"
        title: I18n.t("Доступные в каталоге (", "Available in the catalog (") + page.availableShown.length + ")"
        icon: "download"
        width: parent.width

        PxText {
            visible: page.availableShown.length === 0 && !CommunityPlugins.busy
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: CommunityPlugins.entries.length ? I18n.t("Всё из каталога уже установлено (или ничего не нашлось).", "Everything in the catalog is installed (or nothing matched).") : I18n.t("Каталог пуст. Нажми «Проверить обновления».", "The catalog is empty. Press Check for updates.")
        }
        Repeater {
            model: page.availableShown
            SkinCard {
                id: offer
                required property var modelData
                padding: 0
                group: true
                width: parent.width
                height: offerCol.implicitHeight + Theme.u * 8
                pixelColor: Theme.face

                Column {
                    id: offerCol
                    x: Theme.u * 4
                    y: Theme.u * 4
                    width: parent.width - Theme.u * 8
                    spacing: Theme.u * 2
                    PxText {
                        width: parent.width
                        wrapMode: Text.Wrap
                        font.bold: true
                        text: offer.modelData.name + "  v" + offer.modelData.version
                    }
                    PluginThemeBadge {
                        plugin: offer.modelData
                    }
                    PxText {
                        visible: text !== ""
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: Plugins.themeWarning(offer.modelData)
                        color: Theme.danger
                        kind: "tiny"
                    }
                    PxText {
                        width: parent.width
                        wrapMode: Text.Wrap
                        kind: "tiny"
                        dim: true
                        text: [offer.modelData.author || "", offer.modelData.category || "", (offer.modelData.tags || []).join(", ")].filter(s => s).join("  ·  ")
                    }
                    PxText {
                        width: parent.width
                        wrapMode: Text.Wrap
                        dim: true
                        text: offer.modelData.description || ""
                    }
                    Flow {
                        width: parent.width
                        spacing: Theme.u * 2
                        PxButton {
                            compact: true
                            accent: true
                            icon: "download"
                            text: I18n.t("Установить", "Install")
                            enabled: !CommunityPlugins.busy
                            onClicked: CommunityPlugins.install(offer.modelData)
                        }
                        PxButton {
                            visible: !!offer.modelData.repository
                            compact: true
                            icon: "external"
                            text: I18n.t("Исходники", "Source")
                            onClicked: Quickshell.execDetached(["xdg-open", offer.modelData.repository])
                        }
                        PxButton {
                            compact: true
                            icon: "info"
                            text: I18n.t("Подробности", "Details")
                            onClicked: page.confirmId = page.confirmId === "details:" + offer.modelData.id ? "" : "details:" + offer.modelData.id
                        }
                    }
                    PxText {
                        visible: page.confirmId === "details:" + offer.modelData.id
                        width: parent.width
                        wrapMode: Text.Wrap
                        dim: true
                        text: I18n.t("Лицензия: ", "License: ") + (offer.modelData.license || "—")
                            + I18n.t("\nЗависимости: ", "\nDependencies: ") + ((offer.modelData.dependencies || []).join(", ") || "—")
                            + I18n.t("\nРазрешения: ", "\nPermissions: ") + ((offer.modelData.permissions || []).join(", ") || "—")
                            + (offer.modelData.sha256 ? I18n.t("\nSHA-256 релиза: проверяется", "\nRelease SHA-256: checked") : I18n.t("\nSHA-256 в registry отсутствует", "\nNo SHA-256 in the registry"))
                    }
                }
            }
        }
    }

    PxGroup {
        name: "removed"
        visible: Plugins.removed.length > 0 || page.removeLog !== ""
        title: I18n.t("Удалённые (", "Removed (") + Plugins.removed.length + ")"
        icon: "trash"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Свои плагины лежат в корзине ~/.local/state/angelos/plugin-trash, встроенные просто спрятаны — «Вернуть» ставит их обратно вместе с настройками.", "Your own plugins wait in the trash (~/.local/state/angelos/plugin-trash), bundled ones are only hidden — Restore puts them back with their settings.")
        }
        PxText {
            visible: page.removeLog !== ""
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: page.removeLog
        }
        Repeater {
            model: Plugins.removed
            Item {
                id: gone
                required property var modelData
                width: parent.width
                height: Math.max(goneIcon.height, goneText.implicitHeight, goneButtons.height)
                PxIcon {
                    id: goneIcon
                    anchors.verticalCenter: parent.verticalCenter
                    name: gone.modelData.icon || "plug"
                    pixel: Theme.u
                    opacity: 0.6
                }
                PxText {
                    id: goneText
                    x: goneIcon.width + Theme.u * 4
                    width: parent.width - x - goneButtons.width - Theme.u * 4
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.Wrap
                    text: I18n.label(gone.modelData.name) + (gone.modelData.trashed ? I18n.t("  · в корзине", "  · in the trash") : I18n.t("  · встроенный, спрятан", "  · bundled, hidden"))
                }
                Row {
                    id: goneButtons
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.u * 2
                    PxButton {
                        compact: true
                        icon: "refresh"
                        text: I18n.t("Вернуть", "Restore")
                        onClicked: {
                            page.removeLog = "";
                            Plugins.restore(gone.modelData);
                        }
                    }
                    PxButton {
                        readonly property bool asking: page.confirmId === "erase:" + gone.modelData.dir
                        visible: !!gone.modelData.trashed
                        compact: true
                        danger: true
                        icon: "trash"
                        text: asking ? I18n.t("Стереть навсегда?", "Erase for good?") : ""
                        checked: asking
                        onClicked: {
                            if (!asking) {
                                page.confirmId = "erase:" + gone.modelData.dir;
                                confirmReset.restart();
                                return;
                            }
                            page.confirmId = "";
                            Plugins.erase(gone.modelData);
                        }
                    }
                }
            }
        }
    }

    PxGroup {
        name: "new-plugin"
        title: I18n.t("Новый плагин", "New plugin")
        icon: "plus"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Создаст заготовку со всеми точками встраивания — открой папку и правь QML, потом нажми ↻ у плагина, чтобы он перезагрузился. Или доработай его в Мастере плагинов (кнопка «Доработать»).", "Creates a template with extension points. Open the folder, edit its QML files, then press ↻ next to the plugin to reload it — or improve it in Plugin Studio.")
            dim: true
        }
        Row {
            spacing: Theme.u * 3
            PxField {
                id: newId
                width: Theme.u * 70
                placeholder: I18n.t("id, напр. my-widget", "ID, e.g. my-widget")
            }
            PxField {
                id: newName
                width: Theme.u * 80
                placeholder: I18n.t("Название", "Name")
            }
            PxButton {
                text: I18n.t("Создать", "Create")
                icon: "plus"
                accent: true
                enabled: newId.text.trim() !== ""
                onClicked: Plugins.create(newId.text.trim(), newName.text.trim() || newId.text.trim())
            }
        }
        PxText {
            visible: page.createLog !== ""
            text: page.createLog
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                text: I18n.t("Перечитать плагины", "Reload plugins")
                icon: "refresh"
                onClicked: Plugins.reload()
            }
            PxButton {
                text: I18n.t("Открыть папку", "Open folder")
                icon: "folder"
                onClicked: Shell.openPath(Config.pluginsDir)
            }
        }
    }
}
