pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in limbo: a case file. A grey cardboard folder with its tab, punched for the
// binder; the view is typed on the form inside; a paper clip holds it, and the registry's
// stamp — "received · please wait" — sits on its corner.
HellDress {
    id: dress

    paper: "#dcdad2"
    ink: "#1f2730"
    redInk: "#9b2226"
    title: I18n.t("ДЕЛО 0001 · НАСТРОЙКИ", "CASE 0001 · SETTINGS")
    titleFont: Theme.fontMono
    titlePx: Theme.sizeTitle
    titleColor: "#c9c6bc"
    closer: "#4a4842"
    closerInk: "#dcdad2"
    pageX: Theme.u * 18
    pageTop: headHeight + Theme.u * 4
    pageBottom: Theme.u * 18

    // the folder, its tab above it
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: dress.headHeight - Theme.u * 2
        color: "#5e5b53"
        border.width: Math.max(2, Theme.u)
        border.color: "#2f2d29"
    }
    Rectangle {
        x: Theme.u * 10
        width: Math.min(parent.width * 0.62, Theme.u * 200)
        height: dress.headHeight + Theme.u * 2
        topLeftRadius: Theme.u * 3
        topRightRadius: Theme.u * 3
        color: "#5e5b53"
        border.width: Math.max(2, Theme.u)
        border.color: "#2f2d29"
    }
    // the binder's holes
    Repeater {
        model: 2
        Rectangle {
            required property int index
            x: Theme.u * 6
            y: dress.pageTop + (dress.height - dress.pageTop) * (index ? 0.7 : 0.25)
            width: Theme.u * 6
            height: width
            radius: width / 2
            color: "#1d1c1a"
        }
    }
    // the paper clip over the form's top
    PxIcon {
        z: 2
        bitmap: [".####.", "#....#", "#.##.#", "#.#..#", "#.#..#", "#.#..#", "#.#..#", "#.#..#", "#....#", ".####."]
        pixel: Math.max(1, Theme.u * 2)
        ink: "#9a978e"
        x: dress.pageX + Theme.u * 10
        y: dress.pageTop - Theme.u * 8
    }
    // the registry's stamp
    Rectangle {
        z: 2
        x: dress.width - width - Theme.u * 10
        y: dress.height - dress.pageBottom + (dress.pageBottom - height) / 2
        width: stamp.implicitWidth + Theme.u * 8
        height: stamp.implicitHeight + Theme.u * 4
        rotation: -8
        color: "transparent"
        border.width: Math.max(2, Theme.u)
        border.color: Qt.alpha("#c0393d", 0.9)
        opacity: 0.85
        PxText {
            id: stamp
            anchors.centerIn: parent
            font.bold: true
            color: "#c0393d"
            text: I18n.t("ПРИНЯТО · ОЖИДАЙТЕ", "RECEIVED · PLEASE WAIT")
        }
    }
}
