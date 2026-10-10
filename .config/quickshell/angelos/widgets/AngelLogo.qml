import QtQuick
import qs.config

// angelOS logo: a pixel angel-heart (halo + wings) and a wordmark.
//   classic — "angel" + a Win98 "OS" plate
//   angel   — pink "angel" + cyan "OS" with sparkles
Item {
    id: root

    property bool emblemOnly: false
    property int pixel: Theme.u
    property string variant: Config.bar.logoStyle === "angel" ? "angel" : "classic"
    property int fontSize: Theme.sizeTitle
    readonly property bool angel: variant === "angel"
    // TrollOS emblem: "splat" (red paint splat) or "angel" (the angelOS angel-heart)
    property string emblemStyle: "splat"

    // 13×13 art pixels: 'r' paint splat (the TrollOS sign)
    readonly property var splatRows: [
        ".rr..........",
        ".rrr....r..rr",
        "..rr......rrr",
        "...rr..r.rr..",
        ".r..rrrrrr...",
        "..rrrrrrrr.r.",
        "rr.rrrrrrrrr.",
        "rrrrrrrrrrr..",
        "...rrrrrrrr..",
        "..rrrrrrrrrrr",
        "..r..rrr.r.rr",
        ".....r...r...",
        "....rr......."
    ]


    // 19×12 art pixels: '#' outline, 'o' heart, 'w' wings/shine, 'y' halo
    readonly property var emblemRows: [
        "......yyyyyyy......",
        ".....y.......y.....",
        "......yyyyyyy......",
        "...................",
        "#.....##...##.....#",
        "#w#..#wo#.#oo#..#w#",
        "#ww###ooo#ooo###ww#",
        ".#www#ooooooo#www#.",
        "..#w#.#ooooo#.#w#..",
        "...##..#ooo#..##...",
        "........#o#........",
        ".........#........."
    ]

    implicitWidth: emblemOnly ? emblem.width : row.implicitWidth
    // the 13×13 splat is 1 row taller — don't let it grow the bar
    implicitHeight: Math.max(Math.min(emblem.height, root.pixel * 12), wordmark.implicitHeight)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.pixel * 4

        PxIcon {
            id: emblem
            anchors.verticalCenter: parent.verticalCenter
            bitmap: root.emblemStyle === "splat" ? root.splatRows : root.emblemRows
            pixel: root.pixel
            ink: Theme.dark ? Theme.mix(Theme.accent, Theme.edge, 0.55) : Theme.edge
            fill: Theme.accent
            light: "#ffffff"
            fill3: Theme.mix(Theme.accent3, Qt.color("#ffd84a"), 0.6)
            bad: Theme.mix(Theme.danger, Qt.color("#d00010"), 0.55)
        }

        Row {
            id: wordmark
            visible: !root.emblemOnly
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.angel ? 0 : root.pixel * 2

            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Troll"
                font.family: Theme.fontTitle
                font.pixelSize: root.fontSize
                color: root.angel ? Theme.accent : Theme.text
                style: root.angel ? Text.Outline : Text.Normal
                styleColor: Qt.alpha(Theme.edge, 0.8)
            }

            // classic: "OS" on a bevelled plate
            PxBox {
                visible: !root.angel
                anchors.verticalCenter: parent.verticalCenter
                width: os.implicitWidth + root.pixel * 6
                height: root.fontSize + root.pixel * 2
                color: Theme.accent
                hiColor: Theme.mix(Theme.accent, "#ffffff", 0.45)
                loColor: Theme.mix(Theme.accent, Theme.edge, 0.5)
                PxText {
                    id: os
                    anchors.centerIn: parent
                    text: "OS"
                    font.family: Theme.fontTitle
                    font.pixelSize: root.fontSize
                    font.bold: true
                    color: Theme.selectText
                }
            }

            // angel: cyan "OS" and a sparkle
            PxText {
                visible: root.angel
                anchors.verticalCenter: parent.verticalCenter
                text: "OS"
                font.family: Theme.fontTitle
                font.pixelSize: root.fontSize
                font.bold: true
                color: Theme.accent2
                style: Text.Outline
                styleColor: Qt.alpha(Theme.edge, 0.8)
            }
            PxIcon {
                visible: root.angel
                anchors.top: parent.top
                name: "sparkle"
                pixel: Math.max(1, root.pixel - 1)
                fill: Theme.accent3
            }
        }
    }
}
