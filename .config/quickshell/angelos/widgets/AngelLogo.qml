import QtQuick
import qs.config
import qs.services
import "Logos.js" as Logos

// angelOS logo: an emblem and a wordmark (Settings → Bar → Logo; widgets/Logos.js).
//   wordmarks: classic — "angel" + a Win98 "OS" plate · angel — pink "angel" + cyan "OS"
//              with sparkles · windose — NGO sticker letters, the O is a pill ·
//              hell — gothic red letters with drips · chrome — Y2K silver-to-pink
//   emblems:   splat (TrollOS, the default) · heart (winged, halo) · pill · star · cd · kitty
// While the demon rules (services/Angel) the halo turns into horns (the star turns red).
// `hell` (the Start button in hell, StartButton): hell's colours and the Hell wordmark.
Item {
    id: root

    property bool emblemOnly: false
    property bool hell: false
    property int pixel: Theme.u
    readonly property var variants: ["classic", "angel", "windose", "hell", "chrome"]
    readonly property var emblemNames: ["splat", "heart", "pill", "star", "cd", "kitty"]
    // the Hell wordmark is hell's own: in heaven only once the portal is open (Angel.hellAllowed)
    property string variant: hell ? "hell" : !variants.includes(Config.bar.logoStyle) || (Config.bar.logoStyle === "hell" && !Angel.hellAllowed) ? "classic" : Config.bar.logoStyle
    property string emblemName: emblemNames.includes(Config.bar.logoEmblem) ? Config.bar.logoEmblem : "splat"
    property int fontSize: Theme.sizeTitle
    // one art pixel of a pixel wordmark: the pixel of the 9 px title font at this size,
    // whole (crisp), so the letters match "angel" set in it (scripts/wordmark-art.py)
    property int wordPixel: Math.max(1, Math.round(fontSize / 9))
    readonly property bool angel: variant === "angel"
    readonly property var wordArt: Logos.wordmark(variant)
    // the demon rules — or, in heaven, the pact signed down there left its mark (Story.marked)
    property bool horns: Angel.demon || Story.marked

    readonly property var emblemRows: Logos.emblem(emblemName, horns)
    readonly property bool redStar: horns && !Logos.emblemHasHalo(emblemName)

    implicitWidth: emblemOnly ? emblem.width : row.implicitWidth
    implicitHeight: Math.max(emblem.height, emblemOnly ? 0 : wordArt ? art.height : wordmark.implicitHeight)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.pixel * 4

        PxIcon {
            id: emblem
            anchors.verticalCenter: parent.verticalCenter
            bitmap: root.emblemRows
            pixel: root.pixel
            ink: root.hell ? Theme.hellEdge : Theme.dark ? Theme.mix(Theme.accent, Theme.edge, 0.55) : Theme.edge
            fill: root.hell ? Theme.hellBlood : Theme.accent
            fill2: root.hell ? Theme.hellRim : Theme.accent2
            light: root.hell ? Theme.hellText : "#ffffff"
            fill3: root.hell ? Theme.hellTextDim : root.redStar ? "#e0203a" : Theme.mix(Theme.accent3, Qt.color("#ffd84a"), 0.6)
            bad: root.hell ? Theme.hellAccent : "#e0203a"
            palette: root.hell ? ({
                    "p": Theme.hex(Theme.hellTextDim),
                    "x": Theme.hex(Theme.hellBlood)
                }) : ({
                    "p": Theme.hex(Theme.mix(Theme.accent, "#ffffff", 0.45)),
                    "x": Theme.hex(root.redStar ? Qt.color("#7a0a1e") : Theme.accent2)
                })
        }

        // pixel wordmarks (windose, hell, chrome)
        PxIcon {
            id: art
            visible: !root.emblemOnly && !!root.wordArt
            anchors.verticalCenter: parent.verticalCenter
            bitmap: root.wordArt || []
            pixel: Math.max(1, Math.round(root.wordPixel * Logos.wordmarkScale(root.variant)))
            ink: Theme.dark ? Theme.mix(Theme.accent, Theme.edge, 0.55) : Theme.edge
            fill: Theme.accent
            fill2: Theme.accent2
            fill3: Theme.mix(Theme.accent3, Qt.color("#ffd84a"), 0.6)
            light: "#ffffff"
            body: Theme.mix(Theme.accent2, "#ffffff", 0.55)
            // the Hell wordmark: its loud red in heaven (portal open), the circle's quiet ink in hell
            palette: root.variant === "hell" && root.hell ? {
                "r": Theme.hex(Theme.hellText),
                "d": Theme.hex(Theme.hellRim),
                "k": Theme.hex(Theme.hellEdge),
                "e": Theme.hex(Theme.hellTextDim)
            } : root.variant === "hell" ? {
                "r": "#e0203a",
                "d": "#7a0a1e",
                "k": "#1a0508",
                "e": "#ff6a5a"
            } : {
                "k": Theme.hex(Theme.dark ? Theme.mix(Theme.accent, Theme.edge, 0.55) : Theme.edge),
                "s": "#c8c8d7",
                "g": "#9696aa",
                "p": Theme.hex(Theme.mix(Theme.accent, "#ffffff", 0.45))
            }
        }

        Row {
            id: wordmark
            visible: !root.emblemOnly && !root.wordArt
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
