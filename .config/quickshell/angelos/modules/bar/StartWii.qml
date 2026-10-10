pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Wii "Channels" Start: the whole screen, 4 × 3 rounded channel tiles a page (the
// pinned apps first, then the rest; empty channels striped grey), round ◀ ▶ at the
// sides, and the Wii's curved bottom band with the clock in the middle, a heart button
// (Settings) on the left and a power button on the right. Arrows / wheel / PgUp-PgDn
// walk, Enter runs, typing filters, right click pins, Esc clears / closes.
Item {
    id: root

    signal closeRequested
    property real reveal: 1
    property int current: -1
    property string query: ""
    property int page: 0
    // Settings → Bar → Start → Fine-tune (services/StartPrefs)
    readonly property var prefs: StartPrefs.of("wii")
    readonly property int columns: prefs.columns > 0 ? Math.max(2, Math.min(8, prefs.columns)) : 4
    readonly property int rows: prefs.rows > 0 ? Math.max(1, Math.min(5, prefs.rows)) : 3
    readonly property int perPage: columns * rows
    readonly property bool searching: query.trim() !== ""
    readonly property var list: {
        if (searching)
            return StartApps.search(query);
        const all = StartPrefs.sorted("wii", StartApps.apps);
        if (!prefs.pinned)
            return all;
        const pinned = StartApps.pinned;
        return pinned.concat(all.filter(a => !pinned.includes(a)));
    }
    readonly property int pageCount: Math.max(1, Math.ceil(list.length / perPage))
    readonly property var pageApps: list.slice(page * perPage, (page + 1) * perPage)

    // the Wii's look, in the theme's mood: light or dark
    readonly property color base: Theme.dark ? "#1f2027" : "#eef0f4"
    readonly property color stripe: Theme.dark ? "#25262e" : "#e6e9ee"
    readonly property color tileColor: Theme.dark ? "#2d2f38" : "#ffffff"
    readonly property color tileEdge: Theme.dark ? "#3c3f4a" : "#cfd4dc"
    readonly property color ink: Theme.dark ? "#e8e9ee" : "#5a5f6b"
    readonly property color glow: prefs.accentColor

    function setQuery(t) {
        query = t;
        page = 0;
        current = t ? 0 : -1;
    }
    function reset() {
        query = "";
        page = 0;
        current = -1;
    }
    function run(app) {
        if (!app)
            return;
        closeRequested();
        Qt.callLater(() => StartApps.launch(app));
    }
    function act(fn) {
        closeRequested();
        Qt.callLater(fn);
    }
    function flip(d) {
        page = Math.max(0, Math.min(pageCount - 1, page + d));
        if (current >= 0)
            current = Math.min(list.length - 1, page * perPage);
    }
    function move(dx, dy) {
        if (current < 0) {
            current = page * perPage;
            return;
        }
        const i = current - page * perPage;
        let col = i % columns + dx, row = Math.floor(i / columns) + dy;
        if (col < 0 && page > 0) {
            page--;
            col = columns - 1;
        } else if (col >= columns && page < pageCount - 1) {
            page++;
            col = 0;
        }
        col = Math.max(0, Math.min(columns - 1, col));
        row = Math.max(0, Math.min(rows - 1, row));
        current = Math.min(list.length - 1, page * perPage + row * columns + col);
    }
    function key(e) {
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R) {
            if (searching && e.key === Qt.Key_Escape)
                setQuery("");
            else
                closeRequested();
        } else if (e.key === Qt.Key_Left)
            move(-1, 0);
        else if (e.key === Qt.Key_Right)
            move(1, 0);
        else if (e.key === Qt.Key_Up)
            move(0, -1);
        else if (e.key === Qt.Key_Down)
            move(0, 1);
        else if (e.key === Qt.Key_PageUp)
            flip(-1);
        else if (e.key === Qt.Key_PageDown)
            flip(1);
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            run(list[Math.max(0, current)]);
        else if (e.key === Qt.Key_Backspace) {
            if (searching)
                setQuery(query.slice(0, -1));
        } else if (prefs.search && e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            setQuery(query + e.text);
        else
            return;
        e.accepted = true;
    }

    // ---- the background: soft stripes ----
    Rectangle {
        anchors.fill: parent
        color: root.base
        // Fine-tune → Opacity: the desktop through the stripes
        opacity: root.reveal * (root.prefs.opacity > 0 ? root.prefs.opacity / 100 : 1)
        Column {
            anchors.fill: parent
            Repeater {
                model: Math.ceil(root.height / (Theme.u * 6))
                Rectangle {
                    required property int index
                    width: root.width
                    height: Theme.u * 3
                    color: index % 2 ? root.stripe : root.base
                    Rectangle {
                        y: Theme.u * 3
                        width: root.width
                        height: Theme.u * 3
                        color: root.base
                    }
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
        onWheel: w => root.flip(w.angleDelta.y > 0 || w.angleDelta.x > 0 ? -1 : 1)
    }

    // ---- the channels ----
    readonly property real bandH: Math.round(Math.max(Theme.u * 60, height * 0.2))
    readonly property real gap: Theme.u * 6
    readonly property real tileW: Math.floor(Math.min((width - Theme.u * 70 - gap * (columns - 1)) / columns, ((height - bandH - Theme.u * 40 - gap * (rows - 1)) / rows) * 1.6))
    readonly property real tileH: Math.round(tileW / 1.6)
    Grid {
        id: grid
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round((root.height - root.bandH - height) / 2) + (1 - root.reveal) * Theme.u * 12
        columns: root.columns
        spacing: root.gap
        opacity: root.reveal
        Repeater {
            model: root.perPage
            Item {
                id: ch
                required property int index
                readonly property var app: root.pageApps[index] || null
                readonly property int gindex: root.page * root.perPage + index
                readonly property bool sel: !!app && (root.current === gindex || cm.containsMouse)
                width: root.tileW
                height: root.tileH
                scale: sel ? 1.05 : 1
                z: sel ? 1 : 0
                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.ms(110)
                        easing.type: Easing.OutCubic
                    }
                }
                // the glow ring of the pointed channel
                Rectangle {
                    visible: ch.sel
                    anchors.fill: parent
                    anchors.margins: -Theme.u * 2
                    radius: tile.radius + Theme.u * 2
                    color: "transparent"
                    border.width: Theme.u * 2
                    border.color: Qt.alpha(root.glow, 0.85)
                }
                Rectangle {
                    id: tile
                    anchors.fill: parent
                    radius: height * 0.18
                    color: ch.app ? root.tileColor : root.stripe
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: root.tileEdge
                    clip: true
                    // an empty channel: grey stripes
                    Repeater {
                        model: ch.app ? 0 : 7
                        Rectangle {
                            required property int index
                            x: tile.width * (index / 6) - tile.width * 0.1
                            y: -tile.height * 0.2
                            width: Theme.u * 3
                            height: tile.height * 1.4
                            rotation: 30
                            color: root.tileEdge
                            opacity: 0.6
                        }
                    }
                    // a channel: a soft accent wash, the icon, the name
                    Rectangle {
                        visible: !!ch.app
                        anchors.fill: parent
                        radius: tile.radius
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.alpha(root.glow, 0.0)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.alpha(root.glow, ch.sel ? 0.22 : 0.1)
                            }
                        }
                    }
                    AppIcon {
                        visible: !!ch.app
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Math.round(tile.height * 0.14)
                        iconName: ch.app ? ch.app.icon || "" : ""
                        appId: ch.app ? ch.app.id || "" : ""
                        size: Math.round(tile.height * 0.5 * Math.min(1.3, root.prefs.icons))
                    }
                    PxText {
                        visible: !!ch.app && root.prefs.labels
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Math.round(tile.height * 0.07)
                        width: tile.width - Theme.u * 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        kind: "tiny"
                        font.bold: ch.sel
                        color: root.ink
                        text: ch.app ? ch.app.name : ""
                    }
                    Rectangle {
                        visible: !!ch.app && StartApps.isPinned(ch.app)
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: Theme.u * 4
                        height: width
                        radius: width / 2
                        color: root.glow
                    }
                }
                MouseArea {
                    id: cm
                    anchors.fill: parent
                    enabled: !!ch.app
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: root.current = ch.gindex
                    onClicked: m => m.button === Qt.RightButton ? StartApps.togglePin(ch.app) : root.run(ch.app)
                }
            }
        }
    }

    // ◀ ▶ round page buttons
    component PageButton: Rectangle {
        id: pb
        property int dir: 1
        visible: dir < 0 ? root.page > 0 : root.page < root.pageCount - 1
        width: Theme.u * 22
        height: width
        radius: width / 2
        color: pbm.containsMouse ? Theme.mix(root.tileColor, root.glow, 0.25) : root.tileColor
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.tileEdge
        opacity: root.reveal
        PxIcon {
            anchors.centerIn: parent
            name: pb.dir < 0 ? "arrowLeft" : "arrowRight"
            ink: root.ink
            fill: root.glow
        }
        MouseArea {
            id: pbm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.flip(pb.dir)
        }
    }
    PageButton {
        dir: -1
        x: Math.max(Theme.u * 6, grid.x - width - Theme.u * 10)
        y: grid.y + grid.height / 2 - height / 2
    }
    PageButton {
        dir: 1
        x: Math.min(root.width - width - Theme.u * 6, grid.x + grid.width + Theme.u * 10)
        y: grid.y + grid.height / 2 - height / 2
    }
    // the filter being typed, over the band
    Rectangle {
        visible: root.searching
        anchors.horizontalCenter: parent.horizontalCenter
        y: band.y - height - Theme.u * 6
        width: qText.implicitWidth + Theme.u * 16
        height: qText.implicitHeight + Theme.u * 6
        radius: height / 2
        color: root.tileColor
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.glow
        PxText {
            id: qText
            anchors.centerIn: parent
            color: root.ink
            text: "⌕ " + root.query + (root.list.length ? "" : I18n.t("  — ничего", "  — nothing"))
        }
    }

    component RoundButton: Rectangle {
        id: rb
        property string icon: "heart"
        property string label: ""
        signal hit
        width: Theme.u * 34
        height: width
        radius: width / 2
        y: Math.round(root.bandH * 0.32)
        color: rbm.containsMouse ? Theme.mix(root.tileColor, root.glow, 0.2) : root.tileColor
        border.width: Theme.u
        border.color: rbm.containsMouse ? root.glow : root.tileEdge
        PxIcon {
            anchors.centerIn: parent
            name: rb.icon
            pixel: Theme.u * 2
            ink: root.ink
            fill: root.glow
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: Theme.u
            kind: "tiny"
            color: Qt.alpha(root.ink, 0.8)
            text: rb.label
        }
        MouseArea {
            id: rbm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.hit()
        }
    }
    // ---- the curved bottom band ----
    Item {
        id: band
        width: parent.width
        height: root.bandH
        y: parent.height - height + (1 - root.reveal) * height
        clip: true
        // a huge circle: only its top shows, a gentle arc like the Wii's
        Rectangle {
            readonly property real r: root.width * 2.2
            width: r * 2
            height: r * 2
            radius: r
            x: root.width / 2 - r
            y: Theme.u * 6
            color: root.tileColor
            border.width: Theme.u * 2
            border.color: Qt.alpha(root.glow, 0.7)
        }
        Column {
            visible: root.prefs.clock
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(root.bandH * 0.3)
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                kind: "big"
                font.pixelSize: Theme.sizeBig * 1.6
                color: root.ink
                text: I18n.time(now.date, false)
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.alpha(root.ink, 0.75)
                text: now.date.toLocaleDateString(I18n.locale, "ddd d/M")
            }
        }
        RoundButton {
            x: Theme.u * 30
            icon: "heart"
            label: I18n.t("Настройки", "Settings")
            onHit: root.act(() => Shell.openSettings(""))
        }
        RoundButton {
            visible: root.prefs.power
            x: root.width - width - Theme.u * 30
            icon: "power"
            label: I18n.t("Питание", "Power")
            onHit: root.act(() => Shell.sessionOpen = true)
        }
        // page dots
        Row {
            visible: root.pageCount > 1
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.u * 14
            spacing: Theme.u * 3
            Repeater {
                model: root.pageCount
                Rectangle {
                    required property int index
                    width: Theme.u * 4
                    height: width
                    radius: width / 2
                    color: index === root.page ? root.glow : root.tileEdge
                }
            }
        }
    }
    // the user, top left over the channels
    StartUser {
        visible: root.prefs.user
        x: Theme.u * 16
        y: Theme.u * 12
        opacity: root.reveal
        size: Theme.u * 16
        frameColor: root.glow
        textColor: root.ink
        kind: "title"
        onOpened: root.closeRequested()
    }
    SystemClock {
        id: now
        precision: SystemClock.Minutes
    }
}
