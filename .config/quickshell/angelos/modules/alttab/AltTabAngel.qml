pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Alt+Tab, angelOS style: a pixel "alt+tab.exe" window in the theme colours;
// the pick is framed in the accent with a heart (the desk sprite) on its corner.
Item {
    id: root

    required property var host
    readonly property int cell: Theme.u * 46
    readonly property int perRow: Math.max(1, Math.min(AltTab.items.length, Math.floor(((host.screen ? host.screen.width : 1920) * 0.8) / (cell + Theme.u * 3))))
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    PxWindow {
        id: frame
        anchors.fill: parent
        title: I18n.exe("alt+tab")
        icon: "layers"
        compact: true
        closable: false
        translucent: true
        implicitWidth: grid.width + chrome * 2 + bodyPadding * 2
        implicitHeight: chrome * 2 + titleHeight + bodyPadding * 2 + grid.height + footer.height + Theme.u * 4

        Column {
            spacing: Theme.u * 4
            Grid {
                id: grid
                columns: root.perRow
                spacing: Theme.u * 3
                Repeater {
                    model: AltTab.items
                    Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property bool picked: index === AltTab.index
                        width: root.cell
                        height: root.cell + (Config.alttab.titles ? Theme.u * 10 : 0)
                        PxBox {
                            anchors.fill: parent
                            sunken: card.picked
                            flat: !card.picked
                            outline: card.picked || mouse.containsMouse
                            color: card.picked ? Theme.mix(Theme.face, Theme.accent, 0.35) : mouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : "transparent"
                            edgeColor: card.picked ? Theme.accent : Theme.edge
                        }
                        AppIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: Theme.u * 7
                            appId: card.modelData.app_id || ""
                            size: Theme.u * 26
                            opacity: card.picked ? 1 : 0.8
                        }
                        PxText {
                            visible: Config.alttab.titles
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Theme.u * 3
                            width: parent.width - Theme.u * 4
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.host.appName(card.modelData)
                            kind: "tiny"
                            color: card.picked ? Theme.text : Theme.textDim
                        }
                        WsSprite {
                            visible: card.picked
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.u * 2
                            lit: true
                            pixel: Theme.u
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: AltTab.select(card.index)
                            onClicked: {
                                AltTab.select(card.index);
                                AltTab.commit();
                            }
                        }
                    }
                }
            }
            // the pick's full title and where it lives
            Column {
                id: footer
                width: grid.width
                spacing: Theme.u
                PxText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: "♡ " + (AltTab.current ? (Niri.titleOf(AltTab.current) || root.host.appName(AltTab.current)) : "")
                    font.bold: true
                }
                PxText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.host.place(AltTab.current)
                    kind: "tiny"
                    dim: true
                }
            }
        }
    }
}
