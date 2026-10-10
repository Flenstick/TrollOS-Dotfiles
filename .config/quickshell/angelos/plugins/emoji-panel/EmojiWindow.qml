pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Окно панели: поиск, вкладки, категории, сетка. Печатаешь — ищет,
// стрелки — выбор, Enter — вставить, Tab — следующая вкладка, Esc — закрыть.
PanelWindow {
    // takes input: a click outside the panel closes it, like Windows' Win + .
    id: win

    property var host
    readonly property int u: Theme.u

    property string query: ""
    property int current: 0
    property int emojiCat: 0          // -1 — недавние, 0..8 — группы Unicode
    property int kaoCat: 0
    property int symCat: 0
    property bool tonesOpen: false
    property string hint: ""

    readonly property string tab: host ? host.tab : "emoji"
    readonly property var tabOrder: ["emoji", "kaomoji", "symbols", "clipboard"]
    readonly property var emojiCats: [
        { "i": -1, "e": "🕘", "n": "Недавние" },
        { "i": 0, "e": "😀", "n": "Смайлики и эмоции" },
        { "i": 1, "e": "👋", "n": "Люди и тело" },
        { "i": 2, "e": "🐱", "n": "Животные и природа" },
        { "i": 3, "e": "🍔", "n": "Еда и напитки" },
        { "i": 4, "e": "✈️", "n": "Путешествия и места" },
        { "i": 5, "e": "⚽", "n": "Занятия" },
        { "i": 6, "e": "💡", "n": "Предметы" },
        { "i": 7, "e": "💖", "n": "Символы" },
        { "i": 8, "e": "🏳️", "n": "Флаги" }
    ]
    readonly property string emojiFont: "Noto Color Emoji"

    // всё, что сейчас в сетке: [{s, n}] (+ entry/img для буфера обмена)
    readonly property var results: {
        if (!host)
            return [];
        const q = query.trim().toLowerCase();
        const words = q.split(/\s+/).filter(w => w);
        const hit = str => words.every(w => str.includes(w));
        const tone = host.tone;      // пересчитать при смене тона
        if (tab === "emoji") {
            if (words.length)
                return host.emoji.filter(it => hit(it.k)).slice(0, 240).map(it => ({ "s": host.withTone(it), "n": it.n }));
            if (emojiCat === -1)
                return host.recent;
            return host.emoji.filter(it => it.g === emojiCat).map(it => ({ "s": host.withTone(it), "n": it.n }));
        }
        if (tab === "kaomoji") {
            const cats = words.length ? host.kaomoji.filter(c => hit(c.c)) : host.kaomoji.slice(kaoCat, kaoCat + 1);
            let out = [];
            for (const c of cats)
                out = out.concat(c.items.map(s => ({ "s": s, "n": c.c })));
            if (words.length && out.length === 0)
                for (const c of host.kaomoji)
                    out = out.concat(c.items.filter(s => s.toLowerCase().includes(q)).map(s => ({ "s": s, "n": c.c })));
            return out;
        }
        if (tab === "symbols") {
            let out = [];
            for (const c of (words.length ? host.symbols : host.symbols.slice(symCat, symCat + 1)))
                out = out.concat(c.items.filter(it => !words.length || hit(it.n + " " + c.c) || it.s === q).map(it => ({ "s": it.s, "n": it.n })));
            return out;
        }
        return Clipboard.history.filter(h => h.kind === "image" ? !words.length || hit("картинка image") : hit(String(h.text || "").toLowerCase())).map(h => h.kind === "image" ? ({ "s": "", "n": "картинка", "img": h.path, "entry": h }) : ({ "s": String(h.text || ""), "n": "", "entry": h }));
    }
    readonly property int columns: tab === "emoji" ? 9 : tab === "symbols" ? 8 : tab === "kaomoji" ? 3 : 1

    function pick(i, copyOnly) {
        const r = results[i];
        if (!r)
            return;
        if (r.img)
            host.pasteImage(r.entry, copyOnly);
        else
            host.insert(r.s, r.n, copyOnly);
    }
    function switchTab(t) {
        host.tab = t;
        current = 0;
        tonesOpen = false;
        field.focusField();
    }
    function move(d) {
        if (!results.length)
            return;
        current = Math.max(0, Math.min(results.length - 1, current + d));
        view.positionViewAtIndex(current, GridView.Contain);
    }

    screen: Shell.focusedScreen
    visible: !!host && host.open
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.alpha(Theme.shadow, 0.18)
    WlrLayershell.namespace: "angelos-emoji"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) {
        query = "";
        field.text = "";
        current = 0;
        tonesOpen = false;
        emojiCat = host.recent.length ? -1 : 0;
        field.focusField();
    }
    onResultsChanged: current = Math.min(current, Math.max(0, results.length - 1))

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: win.host.open = false
    }

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: dialog
    }

    PxWindow {
        id: dialog
        anchors.centerIn: parent
        width: win.u * 200
        height: win.u * 226
        title: "эмодзи.txt"
        icon: "heart"
        onCloseClicked: win.host.open = false

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        PxField {
            id: field
            width: parent.width
            icon: "search"
            placeholder: win.tab === "clipboard" ? "поиск в буфере…" : win.tab === "kaomoji" ? "радость, грусть, стол…" : "поиск: кот, сердце, огонь…"
            onEdited: {
                win.query = text;
                win.current = 0;
            }
            onAccepted: win.pick(win.current, false)
            onKeyPressed: e => {
                const k = e.key;
                if (k === Qt.Key_Escape) {
                    win.host.open = false;
                } else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
                    const i = win.tabOrder.indexOf(win.tab);
                    win.switchTab(win.tabOrder[(i + (k === Qt.Key_Tab ? 1 : 3)) % 4]);
                } else if (k === Qt.Key_Down) {
                    win.move(win.columns);
                } else if (k === Qt.Key_Up) {
                    win.move(-win.columns);
                } else if (k === Qt.Key_Right && (win.query === "" || field.input.cursorPosition === field.text.length) && win.columns > 1) {
                    win.move(1);
                } else if (k === Qt.Key_Left && (win.query === "" || field.input.cursorPosition === 0) && win.columns > 1) {
                    win.move(-1);
                } else if ((k === Qt.Key_Return || k === Qt.Key_Enter) && (e.modifiers & Qt.ControlModifier)) {
                    win.pick(win.current, true);      // Ctrl+Enter — только скопировать
                } else {
                    return;
                }
                e.accepted = true;
            }
        }

        // ---- вкладки ----
        PxSegmented {
            id: tabs
            y: field.height + win.u * 3
            model: [
                { "label": "😀 Эмодзи", "value": "emoji" },
                { "label": "(◕‿◕)", "value": "kaomoji" },
                { "label": "Ω Символы", "value": "symbols" },
                { "label": "Буфер", "value": "clipboard", "icon": "package" }
            ]
            currentValue: win.tab
            onActivated: v => win.switchTab(v)
        }

        // ---- категории ----
        Item {
            id: cats
            y: tabs.y + tabs.height + win.u * 3
            width: parent.width
            height: win.tab === "clipboard" ? 0 : win.u * 15
            visible: height > 0 && win.query.trim() === ""

            // эмодзи: иконки групп + тон кожи
            Row {
                visible: win.tab === "emoji"
                spacing: 0
                Repeater {
                    model: win.emojiCats
                    Rectangle {
                        id: catBtn
                        required property var modelData
                        readonly property bool sel: win.emojiCat === modelData.i
                        width: win.u * 16
                        height: win.u * 15
                        color: sel ? Qt.alpha(Theme.accent, 0.35) : catMouse.containsMouse ? Qt.alpha(Theme.accent, 0.15) : "transparent"
                        Rectangle {
                            visible: catBtn.sel
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: win.u
                            color: Theme.accent
                        }
                        Text {
                            anchors.centerIn: parent
                            text: catBtn.modelData.e
                            font.family: win.emojiFont
                            font.pixelSize: win.u * 8
                        }
                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.hint = catBtn.modelData.n
                            onExited: win.hint = ""
                            onClicked: {
                                win.emojiCat = catBtn.modelData.i;
                                win.current = 0;
                                view.positionViewAtBeginning();
                                field.focusField();
                            }
                        }
                    }
                }
            }
            Rectangle {
                visible: win.tab === "emoji"
                anchors.right: parent.right
                width: win.u * 16
                height: win.u * 15
                color: toneMouse.containsMouse || win.tonesOpen ? Qt.alpha(Theme.accent, 0.2) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✋" + (win.host ? win.host.tones[win.host.tone] : "")
                    font.family: win.emojiFont
                    font.pixelSize: win.u * 8
                }
                MouseArea {
                    id: toneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: win.hint = "Тон кожи"
                    onClicked: win.tonesOpen = !win.tonesOpen
                }
            }

            // каомодзи и символы: названия категорий, листаются колёсиком
            ListView {
                visible: win.tab === "kaomoji" || win.tab === "symbols"
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: win.u * 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: win.tab === "kaomoji" ? (win.host ? win.host.kaomoji : []) : (win.host ? win.host.symbols : [])
                delegate: PxButton {
                    required property var modelData
                    required property int index
                    compact: true
                    text: modelData.c
                    checked: (win.tab === "kaomoji" ? win.kaoCat : win.symCat) === index
                    onClicked: {
                        if (win.tab === "kaomoji")
                            win.kaoCat = index;
                        else
                            win.symCat = index;
                        win.current = 0;
                        view.positionViewAtBeginning();
                        field.focusField();
                    }
                }
                WheelHandler {
                    onWheel: e => parent.flick(e.angleDelta.y * 8, 0)
                }
            }
        }

        // ---- сетка ----
        PxBox {
            id: box
            y: cats.y + (cats.visible ? cats.height + win.u * 3 : 0)
            width: parent.width
            height: parent.height - y - footer.height - win.u * 3
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.75)

            PxText {
                visible: win.results.length === 0
                anchors.centerIn: parent
                width: parent.width - win.u * 20
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: win.tab === "emoji" && win.emojiCat === -1 && !win.query ? "тут появятся эмодзи, которые ты выбирал ♡" : win.tab === "clipboard" && !win.query ? "пусто… скопируй что-нибудь ♡" : "ничего не нашлось ♡"
                dim: true
            }

            GridView {
                id: view
                anchors.fill: parent
                anchors.margins: win.u * 2
                clip: true
                model: win.results
                cellWidth: Math.floor(width / win.columns)
                cellHeight: win.tab === "clipboard" ? win.u * 22 : win.tab === "kaomoji" ? win.u * 16 : cellWidth
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 400
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === win.current
                    width: view.cellWidth
                    height: view.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: win.u / 2
                        radius: win.u * 2
                        color: cell.sel ? Qt.alpha(Theme.accent, 0.45) : m.containsMouse ? Qt.alpha(Theme.accent, 0.2) : "transparent"
                        border.width: cell.sel ? 1 : 0
                        border.color: Theme.accent
                    }
                    // эмодзи / символ / каомодзи
                    Text {
                        visible: win.tab !== "clipboard"
                        anchors.centerIn: parent
                        width: parent.width - win.u * 3
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: cell.modelData.s
                        color: Theme.text
                        font.family: win.tab === "emoji" ? win.emojiFont : ""
                        font.pixelSize: win.tab === "emoji" ? win.u * 11 : win.tab === "symbols" ? win.u * 10 : win.u * 7
                    }
                    // буфер обмена
                    Row {
                        visible: win.tab === "clipboard"
                        x: win.u * 3
                        width: parent.width - win.u * 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: win.u * 3
                        Image {
                            visible: !!cell.modelData.img
                            width: visible ? win.u * 28 : 0
                            height: win.u * 18
                            source: cell.modelData.img ? "file://" + cell.modelData.img : ""
                            sourceSize.height: win.u * 36
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }
                        PxText {
                            width: parent.width - (cell.modelData.img ? win.u * 31 : 0)
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.modelData.img ? "Картинка" : cell.modelData.s.replace(/\s+/g, " ").slice(0, 200)
                            maximumLineCount: 2
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                            color: Theme.text
                        }
                    }
                    MouseArea {
                        id: m
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onExited: win.hint = ""
                        onEntered: win.hint = cell.modelData.img ? "картинка" : (win.tab === "clipboard" ? "" : cell.modelData.s + "  ") + (cell.modelData.n || "")
                        onClicked: e => win.pick(cell.index, e.button === Qt.RightButton)
                    }
                }
            }

            // выбор тона кожи поверх сетки
            PxBox {
                visible: win.tonesOpen
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: win.u * 2
                width: toneRow.implicitWidth + win.u * 6
                height: win.u * 20
                color: Theme.face
                Row {
                    id: toneRow
                    anchors.centerIn: parent
                    Repeater {
                        model: 6
                        Rectangle {
                            id: toneCell
                            required property int index
                            width: win.u * 16
                            height: win.u * 16
                            radius: win.u * 2
                            color: win.host && win.host.tone === index ? Qt.alpha(Theme.accent, 0.45) : tm.containsMouse ? Qt.alpha(Theme.accent, 0.2) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "✋" + (win.host ? win.host.tones[toneCell.index] : "")
                                font.family: win.emojiFont
                                font.pixelSize: win.u * 9
                            }
                            MouseArea {
                                id: tm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.host.setTone(toneCell.index);
                                    win.tonesOpen = false;
                                    field.focusField();
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- подсказка снизу ----
        Item {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width
            height: win.u * 10
            PxText {
                anchors.left: parent.left
                anchors.right: keysHint.left
                anchors.rightMargin: win.u * 4
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const r = win.results[win.current];
                    if (win.hint)
                        return win.hint;
                    return r ? (r.img ? "картинка" : win.tab === "clipboard" ? "" : r.s + "  " + (r.n || "")) : "";
                }
                elide: Text.ElideRight
                kind: "tiny"
                color: Theme.text
            }
            PxText {
                id: keysHint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Enter — вставить · ПКМ — копировать"
                kind: "tiny"
                dim: true
            }
        }
    }

    // сбросить подсказку наведения, когда мышь ушла с сетки
    onCurrentChanged: hint = ""

    // см. RightClickGuard в angelOS (из плагина он не виден)
    MouseArea {
        z: -1
        width: 1
        height: 1
        acceptedButtons: Qt.RightButton
    }
}
