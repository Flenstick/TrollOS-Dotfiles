pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Windows 11-like Start: search on top, pinned apps grid, "All apps" list,
// recommended row, user + power at the bottom. Right-click pins/unpins.
PxBox {
    id: root

    signal closeRequested
    property int current: -1
    property bool showAll: false
    property string query: ""
    // Settings → Bar → Start → Fine-tune (services/StartPrefs): width, the pinned grid,
    // icons, sections, colours, order
    readonly property var prefs: StartPrefs.of("win11")
    readonly property real sizeFactor: prefs.size
    readonly property int columns: prefs.columns > 0 ? Math.max(3, Math.min(10, prefs.columns)) : Math.max(4, Math.min(10, Math.round(6 * sizeFactor)))
    property real room: 0                       // StartOverlay: the screen's room for it
    // the pinned rows that fit in it (big fonts, a big art pixel, a small screen): the menu
    // gives up rows rather than run off the screen
    readonly property int fitRows: room > 0 ? Math.floor((room - footer.height - Theme.u * 10 - (field.visible ? field.height : 0) - head.implicitHeight - (recHead.visible ? recHead.implicitHeight + recFlow.implicitHeight : 0) - col.spacing * 4) / grid.cellHeight) : 6
    readonly property int rows: Math.max(1, Math.min(6, fitRows, prefs.rows > 0 ? prefs.rows : 3))
    readonly property color accentColor: prefs.accentColor
    readonly property var appList: StartPrefs.sorted("win11", StartApps.apps)
    // typing turns the grid into a Windows 11-like list: the calculator, apps and settings by relevance
    readonly property bool searching: query.trim() !== ""
    readonly property var results: searching ? StartApps.searchAll(query, 40) : []
    readonly property var shown: searching ? results : showAll || !prefs.pinned ? appList : StartApps.pinned.slice(0, columns * rows)
    readonly property var recommended: [
        {
            "text": I18n.t("Настройки", "Settings"),
            "hint": I18n.t("тема, обои, панель", "theme, wallpaper, bar"),
            "icon": "gear",
            "act": () => Shell.openSettings()
        },
        {
            "text": I18n.t("Обои", "Wallpaper"),
            "hint": I18n.t("выбрать картинку", "pick a picture"),
            "icon": "image",
            "act": () => Shell.openSettings("wallpaper")
        },
        {
            "text": I18n.t("Файлы", "Files"),
            "hint": I18n.t("домашняя папка", "home folder"),
            "icon": "folder",
            "act": () => Shell.exec([Config.system.fileManager || "xdg-open", Config.home])
        },
        {
            "text": I18n.t("Терминал", "Terminal"),
            "hint": Config.system.terminal || "kitty",
            "icon": "terminal",
            "act": () => Shell.terminal()
        }
    ]

    function setQuery(t) {
        field.text = t;
        query = t;
        current = t ? 0 : -1;
    }
    function reset() {
        current = -1;
        showAll = !prefs.pinned;
        query = "";
        field.text = "";
        if (prefs.typeSearch && prefs.search)
            Qt.callLater(() => field.focusField());
    }
    function run(app) {
        closeRequested();
        Qt.callLater(() => StartApps.launch(app));
    }
    // a search row: launch the app, open the setting, copy the sum
    function activate(row) {
        if (!row)
            return;
        if (!searching)
            run(row);
        else if (row.kind === "app")
            run(row.app);
        else if (row.kind === "setting")
            act(() => StartApps.openSetting(row.doc));
        else if (row.kind === "file")
            act(() => FileSearch.open(row.file));
        else if (row.kind === "calc") {
            Calc.copy(row.calc);
            if (row.calc.copy)
                closeRequested();
        }
    }
    function act(fn) {
        closeRequested();
        Qt.callLater(fn);
    }
    function move(dx, dy) {
        const n = shown.length;
        if (!n)
            return;
        if (current < 0) {
            current = 0;
            return;
        }
        const linear = (showAll && !query) || searching;
        const step = linear ? dy : dy * columns + dx;
        current = Math.max(0, Math.min(n - 1, current + (linear ? dy + dx : step)));
        if (showAll && !query)
            allList.positionViewAtIndex(current, ListView.Contain);
        if (searching)
            resultList.positionViewAtIndex(current, ListView.Contain);
    }
    // the overlay forwards the first key here; the search field takes the rest
    function key(e) {
        if (nav(e))
            return;
        if (e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            field.text += e.text;
            query = field.text;
            field.focusField();
            e.accepted = true;
        }
    }
    function nav(e) {
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R)
            closeRequested();
        else if (e.key === Qt.Key_Down)
            move(0, 1);
        else if (e.key === Qt.Key_Up)
            move(0, -1);
        else if (e.key === Qt.Key_Right && query === "")
            move(1, 0);
        else if (e.key === Qt.Key_Left && query === "")
            move(-1, 0);
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            activate(shown[Math.max(0, current)]);
        else
            return false;
        e.accepted = true;
        return true;
    }

    width: Math.round(Theme.u * 250 * sizeFactor)
    height: col.implicitHeight + footer.height + Theme.u * 10
    color: Qt.alpha(Theme.menuSurface, prefs.alpha)
    edgeColor: Theme.menuBorder
    flat: true
    shadow: Config.appearance.shadows && prefs.shadow

    // the pinned grid: a ListModel of indexes into gridSrc, so a drag moves the tiles
    // themselves (the others slide aside) instead of rebuilding the grid
    property var gridSrc: []
    property int dragIdx: -1          // the tile being dragged, -1 none
    ListModel {
        id: pinModel
    }
    function syncGrid() {
        if (dragIdx >= 0)
            return;
        const src = grid.visible ? shown : [];
        const same = src.length === pinModel.count && src.every((a, i) => gridSrc[pinModel.get(i).k] === a);
        gridSrc = src;
        if (same) {
            for (let i = 0; i < pinModel.count; i++)
                pinModel.setProperty(i, "k", i);
            return;
        }
        pinModel.clear();
        for (let i = 0; i < src.length; i++)
            pinModel.append({
                "k": i
            });
    }
    onShownChanged: Qt.callLater(syncGrid)
    Component.onCompleted: syncGrid()
    function saveOrder() {
        const ids = [];
        for (let i = 0; i < pinModel.count; i++)
            ids.push((gridSrc[pinModel.get(i).k] || {}).id);
        StartApps.setOrder(ids);
    }

    component Tile: Item {
        id: tile
        required property int k
        required property int index
        readonly property var modelData: root.gridSrc[k] || ({})
        readonly property bool sel: root.current === index
        readonly property bool dragging: root.dragIdx === index && tm.dragged
        readonly property bool canDrag: !root.searching && !root.showAll && root.prefs.pinned
        width: grid.cellWidth
        height: grid.cellHeight
        z: dragging || drop.running ? 10 : 0

        // where the pointer took the tile, and how far it is from its slot now
        property point grab
        property real dx: 0
        property real dy: 0
        property real lift: 0          // 0..1 поднята
        property real wob: 0           // покачивание в руке
        function slotX(i) {
            return (i % root.columns) * grid.cellWidth;
        }
        function slotY(i) {
            return Math.floor(i / root.columns) * grid.cellHeight;
        }
        transform: [
            Translate {
                x: tile.dx
                y: tile.dy
            },
            Rotation {
                origin.x: tile.width / 2
                origin.y: tile.height / 2
                angle: tile.lift * Math.sin(tile.wob) * 4
            }
        ]
        Behavior on lift {
            NumberAnimation {
                duration: Motion.ms(160)
                easing.type: Easing.OutBack
                easing.overshoot: 2.5
            }
        }
        NumberAnimation on wob {
            running: tile.dragging
            from: 0
            to: Math.PI * 2
            duration: 520
            loops: Animation.Infinite
        }
        ParallelAnimation {
            id: drop
            NumberAnimation {
                target: tile
                property: "dx"
                to: 0
                duration: Motion.ms(260)
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: tile
                property: "dy"
                to: 0
                duration: Motion.ms(260)
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Motion.ms(160)
                }
                // встала на место: короткий «кивок»
                NumberAnimation {
                    target: tile
                    property: "scale"
                    to: 0.92
                    duration: Motion.ms(70)
                }
                NumberAnimation {
                    target: tile
                    property: "scale"
                    to: 1
                    duration: Motion.ms(180)
                    easing.type: Easing.OutBack
                    easing.overshoot: 3
                }
            }
        }
        // тень под поднятой плиткой
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.u * 2
            anchors.topMargin: Theme.u * 2 + tile.lift * Theme.u * 3
            anchors.leftMargin: Theme.u * 2 + tile.lift * Theme.u * 2
            anchors.rightMargin: Theme.u * 2 - tile.lift * Theme.u * 2
            anchors.bottomMargin: Theme.u * 2 - tile.lift * Theme.u * 3
            color: Qt.alpha(Theme.shadow, 0.45 * tile.lift)
            visible: tile.lift > 0.01
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.u
            color: tile.lift > 0.01 ? Qt.alpha(Theme.mix(Theme.menuSurface, root.accentColor, 0.35), 0.92 * tile.lift) : tile.sel ? Qt.alpha(root.accentColor, 0.3) : tm.containsMouse ? Qt.alpha(root.accentColor, 0.14) : "transparent"
            border.width: tile.sel || tile.lift > 0.01 ? Math.max(1, Theme.u / 2) : 0
            border.color: root.accentColor
        }
        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.u * 4
            spacing: Theme.u * 2
            scale: 1 + tile.lift * 0.12
            AppIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                iconName: tile.modelData.icon || ""
                appId: tile.modelData.id || ""
                size: Math.round(Theme.u * 15 * root.prefs.icons)
                scale: tm.pressed && !tm.dragged ? 0.88 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.ms(90)
                    }
                }
            }
            PxText {
                visible: root.prefs.labels
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: tile.modelData.name || ""
                kind: "tiny"
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
        PxIcon {
            visible: StartApps.isPinned(tile.modelData) && !root.query && tm.containsMouse && root.dragIdx < 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.u * 2
            name: "pin"
            pixel: Math.max(1, Theme.u - 1)
        }
        MouseArea {
            id: tm
            // зажми и тащи — плитка поднимается, остальные расступаются
            property bool dragged: false
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            onEntered: if (root.dragIdx < 0)
                root.current = tile.index
            onPressed: m => {
                dragged = false;
                tile.grab = mapToItem(grid.contentItem, m.x, m.y);
                drop.stop();
            }
            onPositionChanged: m => {
                if (!pressed || !(pressedButtons & Qt.LeftButton) || !tile.canDrag)
                    return;
                const p = mapToItem(grid.contentItem, m.x, m.y);
                if (!dragged) {
                    if (Math.hypot(p.x - tile.grab.x, p.y - tile.grab.y) < Theme.u * 4)
                        return;
                    dragged = true;
                    root.dragIdx = tile.index;
                    root.current = -1;
                    tile.lift = 1;
                    // grab stays relative to the tile's slot
                    tile.grab = Qt.point(tile.grab.x - tile.slotX(tile.index), tile.grab.y - tile.slotY(tile.index));
                }
                // the slot under the pointer
                const col = Math.max(0, Math.min(root.columns - 1, Math.floor(p.x / grid.cellWidth)));
                const row = Math.max(0, Math.floor(p.y / grid.cellHeight));
                const to = Math.max(0, Math.min(pinModel.count - 1, row * root.columns + col));
                if (to !== tile.index) {
                    pinModel.move(tile.index, to, 1);
                    root.dragIdx = to;
                }
                // by the slot's maths: the grid lays the moved tile out a frame later
                tile.dx = p.x - tile.grab.x - tile.slotX(root.dragIdx);
                tile.dy = p.y - tile.grab.y - tile.slotY(root.dragIdx);
            }
            onReleased: {
                if (!dragged)
                    return;
                tile.lift = 0;
                drop.restart();
                root.dragIdx = -1;
                root.saveOrder();
            }
            onCanceled: {
                if (dragged) {
                    tile.lift = 0;
                    drop.restart();
                    root.dragIdx = -1;
                    root.saveOrder();
                }
                dragged = false;
            }
            onClicked: m => {
                if (dragged) {
                    dragged = false;
                    return;
                }
                m.button === Qt.RightButton ? StartApps.togglePin(tile.modelData) : root.run(tile.modelData);
            }
        }
        onIndexChanged: if (tm.dragged && root.dragIdx >= 0 && root.dragIdx !== index)
            root.dragIdx = index
    }

    Column {
        id: col
        x: Theme.u * 6
        y: Theme.u * 6
        width: parent.width - Theme.u * 12
        spacing: Theme.u * 5

        PxField {
            id: field
            visible: root.prefs.search
            keepFocus: true
            width: parent.width
            icon: "search"
            placeholder: Config.launcher.settings !== false ? I18n.t("Приложения, настройки, 2+2…", "Apps, settings, 2+2…") : I18n.t("Поиск приложений…", "Search apps…")
            onEdited: {
                root.query = text;
                root.current = text ? 0 : -1;
            }
            onAccepted: if (root.shown.length)
                root.activate(root.shown[Math.max(0, root.current)])
            onKeyPressed: e => root.nav(e)
        }

        Item {
            width: parent.width
            height: head.implicitHeight
            PxText {
                id: head
                text: root.query ? (root.results.length ? I18n.t("Лучшие совпадения", "Best matches") : I18n.t("Ничего не нашлось", "Nothing found")) : root.showAll ? I18n.t("Все приложения", "All apps") : I18n.t("Закреплённые", "Pinned")
                kind: "title"
                anchors.verticalCenter: parent.verticalCenter
            }
            PxButton {
                visible: !root.query && root.prefs.pinned
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                text: root.showAll ? I18n.t("‹ Назад", "‹ Back") : I18n.t("Все приложения ›", "All apps ›")
                onClicked: {
                    root.showAll = !root.showAll;
                    root.current = -1;
                }
            }
        }

        // search results: one list, best first
        ListView {
            id: resultList
            visible: root.searching
            width: parent.width
            height: grid.cellHeight * root.rows + recHead.implicitHeight + Theme.u * 5
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: visible ? root.results : []
            delegate: Rectangle {
                id: hit
                required property var modelData
                required property int index
                readonly property bool sel: root.current === index
                readonly property bool isCalc: modelData.kind === "calc"
                readonly property bool isFile: modelData.kind === "file"
                width: resultList.width
                height: isCalc ? Theme.fit(22) : Theme.fit(16)
                color: sel ? Qt.alpha(root.accentColor, 0.3) : hm.containsMouse ? Qt.alpha(root.accentColor, 0.14) : "transparent"
                border.width: sel ? Math.max(1, Theme.u / 2) : 0
                border.color: root.accentColor
                Item {
                    id: hitIcon
                    x: Theme.u * 3
                    width: Theme.u * 12
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    AppIcon {
                        visible: hit.modelData.kind === "app"
                        anchors.centerIn: parent
                        iconName: visible ? hit.modelData.app.icon || "" : ""
                        appId: visible ? hit.modelData.app.id || "" : ""
                        size: Theme.u * 12
                    }
                    FileThumb {
                        id: hitThumb
                        visible: ok
                        anchors.fill: parent
                        hit: hit.isFile ? hit.modelData.file : null
                    }
                    PxIcon {
                        visible: hit.modelData.kind !== "app" && !hitThumb.ok
                        anchors.centerIn: parent
                        name: hit.isCalc ? "calc" : hit.modelData.kind === "setting" ? hit.modelData.doc.icon || "gear" : hit.isFile ? FileSearch.pixelIcon(hit.modelData.file) : "sparkle"
                    }
                }
                Column {
                    anchors.left: hitIcon.right
                    anchors.leftMargin: Theme.u * 5
                    anchors.right: hitKind.left
                    anchors.rightMargin: Theme.u * 3
                    anchors.verticalCenter: parent.verticalCenter
                    PxText {
                        width: parent.width
                        elide: Text.ElideRight
                        kind: hit.isCalc ? "title" : "body"
                        font.bold: hit.sel || hit.isCalc
                        text: hit.isCalc ? hit.modelData.calc.title : hit.modelData.kind === "app" ? hit.modelData.app.name : hit.isFile ? hit.modelData.file.name : hit.modelData.doc.title
                    }
                    PxText {
                        width: parent.width
                        visible: text !== ""
                        elide: Text.ElideRight
                        kind: "tiny"
                        dim: true
                        text: hit.isCalc ? hit.modelData.calc.subtitle : hit.modelData.kind === "app" ? (hit.modelData.app.genericName || hit.modelData.app.comment || "") : hit.isFile ? FileSearch.where(hit.modelData.file) : (hit.modelData.doc.crumb || hit.modelData.doc.hint || "")
                    }
                }
                PxText {
                    id: hitKind
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.u * 4
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "tiny"
                    dim: true
                    text: hit.isCalc ? (hit.modelData.calc.copy ? "⧉" : "") : hit.modelData.kind === "app" ? I18n.t("приложение", "app") : hit.isFile ? (hit.modelData.file.isDir ? I18n.t("папка", "folder") : I18n.t("файл", "file")) : I18n.t("настройка", "setting")
                }
                MouseArea {
                    id: hm
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = hit.index
                    onClicked: m => {
                        if (m.button === Qt.RightButton && hit.modelData.kind === "app")
                            StartApps.togglePin(hit.modelData.app);
                        else if (m.button === Qt.RightButton && hit.isFile)
                            root.act(() => FileSearch.reveal(hit.modelData.file));
                        else
                            root.activate(hit.modelData);
                    }
                }
            }
        }

        // pinned grid
        GridView {
            id: grid
            visible: !root.showAll && !root.searching
            width: parent.width
            height: cellHeight * Math.max(1, Math.min(root.rows, Math.ceil(count / root.columns)))
            cellWidth: width / root.columns
            cellHeight: Math.round(Theme.u * 22 * Math.max(0.8, root.prefs.icons)) + (root.prefs.labels ? Theme.fit(8) : 0)
            interactive: count > root.columns * root.rows && root.dragIdx < 0
            clip: true
            model: pinModel
            delegate: Tile {}
            onVisibleChanged: root.syncGrid()
            // расступаются плавно
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: Motion.ms(220)
                    easing.type: Easing.OutCubic
                }
            }
            move: Transition {}
        }

        // all apps, alphabetical with letter headers
        ListView {
            id: allList
            visible: root.showAll && root.query === ""
            width: parent.width
            height: grid.cellHeight * root.rows + recHead.implicitHeight + recFlow.implicitHeight + Theme.u * 5
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: allList.visible ? root.shown : []
            delegate: Item {
                id: li
                required property var modelData
                required property int index
                readonly property string letter: String(modelData.name || "?").charAt(0).toUpperCase()
                readonly property bool first: index === 0 || letter !== String(root.shown[index - 1].name || "?").charAt(0).toUpperCase()
                width: allList.width
                height: row.height + (first ? letterText.implicitHeight + Theme.u * 2 : 0)
                PxText {
                    id: letterText
                    visible: li.first
                    text: li.letter
                    kind: "title"
                    color: root.accentColor
                    topPadding: Theme.u * 2
                }
            Rectangle {
                id: row
                y: li.first ? letterText.implicitHeight + Theme.u * 2 : 0
                width: allList.width
                height: Theme.fit(14)
                color: root.current === li.index ? Qt.alpha(root.accentColor, 0.3) : lm.containsMouse ? Qt.alpha(root.accentColor, 0.14) : "transparent"
                Row {
                    x: Theme.u * 3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.u * 4
                    AppIcon {
                        iconName: li.modelData.icon || ""
                        appId: li.modelData.id || ""
                        size: Math.round(Theme.u * 10 * root.prefs.icons)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PxText {
                        text: li.modelData.name
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: lm
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = li.index
                    onClicked: m => m.button === Qt.RightButton ? StartApps.togglePin(li.modelData) : root.run(li.modelData)
                }
            }
            }
        }

        PxText {
            id: recHead
            visible: !root.showAll && !root.query && root.prefs.recommended
            text: I18n.t("Рекомендуем", "Recommended")
            kind: "title"
        }
        Flow {
            id: recFlow
            visible: !root.showAll && !root.query && root.prefs.recommended
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: root.recommended
                Rectangle {
                    id: rec
                    required property var modelData
                    width: (recFlow.width - recFlow.spacing) / 2
                    height: Theme.fit(17)
                    color: rm.containsMouse ? Qt.alpha(root.accentColor, 0.14) : "transparent"
                    Row {
                        x: Theme.u * 3
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 4
                        PxIcon {
                            name: rec.modelData.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: rec.width - Theme.u * 20
                            PxText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: rec.modelData.text
                            }
                            PxText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: rec.modelData.hint
                                kind: "tiny"
                                dim: true
                            }
                        }
                    }
                    MouseArea {
                        id: rm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act(rec.modelData.act)
                    }
                }
            }
        }
    }

    // user + power
    Rectangle {
        id: footer
        visible: root.prefs.user || root.prefs.power
        anchors.bottom: parent.bottom
        width: parent.width
        height: visible ? Theme.u * 20 : 0
        color: Qt.alpha(Theme.menuHeader, 0.55)
        Rectangle {
            width: parent.width
            height: Theme.u
            color: Theme.menuBorder
        }
        StartUser {
            visible: root.prefs.user
            x: Theme.u * 8
            anchors.verticalCenter: parent.verticalCenter
            frameColor: root.accentColor
            onOpened: root.closeRequested()
        }
        Row {
            visible: root.prefs.power
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: "download"
                accent: Updates.available
                onClicked: root.act(() => Shell.openSettings("updates"))
            }
            PxButton {
                compact: true
                icon: "lock"
                onClicked: root.act(() => Shell.lock())
            }
            PxButton {
                compact: true
                icon: "power"
                onClicked: root.act(() => Shell.sessionOpen = true)
            }
        }
    }
}
