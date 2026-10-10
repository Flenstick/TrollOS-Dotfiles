import QtQuick
import qs.config

// The three icon styles side by side (Settings → Appearance → Icons, the setup wizard; D3):
// each card is a strip of the same icons drawn in that style — the preview is the choice.
// A click picks it; everything that draws a PxIcon follows at once.
Column {
    id: root
    width: parent ? parent.width : implicitWidth
    spacing: Theme.u * 2
    readonly property var samples: ["gear", "folder", "search", "bell", "trash", "music", "calendar", "refresh", "image", "lock"]
    readonly property var styles: [
        {
            "value": "angelos",
            "label": "angelOS",
            "hint": I18n.t("свои, цветные, крупный пиксель", "Our own: in colour, a big pixel")
        },
        {
            "value": "pixelarticons",
            "label": "pixelarticons",
            "hint": I18n.t("строгие, одним цветом · MIT", "Strict, one colour · MIT")
        },
        {
            "value": "hackernoon",
            "label": "HackerNoon Pixel Icons",
            "hint": I18n.t("тонкие, мелкий пиксель · CC BY 4.0", "Thin, a fine pixel · CC BY 4.0")
        }
    ]
    Repeater {
        model: root.styles
        Rectangle {
            id: card
            required property var modelData
            readonly property bool chosen: (Config.appearance.iconStyle || "angelos") === modelData.value
            width: root.width
            height: cardCol.implicitHeight + Theme.u * 6
            color: chosen ? Theme.mix(Theme.face, Theme.accent, 0.2) : (hover.hovered ? Theme.mix(Theme.face, Theme.accent, 0.08) : Theme.face)
            border.width: Math.max(1, Theme.u / 2)
            border.color: chosen ? Theme.accent : Theme.lo
            clip: true
            Column {
                id: cardCol
                x: Theme.u * 3
                y: Theme.u * 3
                width: parent.width - Theme.u * 6
                spacing: Theme.u * 2
                Flow {
                    width: parent.width
                    spacing: Theme.u * 2
                    Repeater {
                        model: root.samples
                        Item {
                            required property string modelData
                            width: Theme.u * 12
                            height: Theme.u * 12
                            PxIcon {
                                anchors.centerIn: parent
                                name: parent.modelData
                                iconStyle: card.modelData.value
                            }
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: Theme.u * 3
                    PxIcon {
                        id: mark
                        anchors.verticalCenter: parent.verticalCenter
                        name: card.chosen ? "heart" : "sparkle"
                        iconStyle: "angelos"
                    }
                    PxText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - mark.width - parent.spacing
                        text: card.modelData.label
                        wrapMode: Text.Wrap
                    }
                }
                PxText {
                    width: parent.width
                    text: card.modelData.hint
                    kind: "tiny"
                    dim: true
                    wrapMode: Text.Wrap
                }
            }
            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: Config.appearance.iconStyle = card.modelData.value
            }
        }
    }
}
