pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of greed: the ledger. A book in green cloth with brass corners, the
// view entered on its ruled page; beside it the narrow column of the totals, ruled in red,
// ending in a sum nobody will ever pay, and a stack of coins on the cover.
HellDress {
    id: dress

    paper: "#e3eadb"
    ink: "#1d2e22"
    redInk: "#a01b1b"
    title: I18n.t("Главная книга · счёт настроек", "General ledger · the Settings account")
    titleColor: "#d8b862"
    closer: "#2b4a33"
    closerInk: "#d8b862"
    pageX: Theme.u * 10
    pageRight: Theme.u * 46
    pageBottom: Theme.u * 10
    pageEdge: "#9fb39a"
    pageEdgeWidth: Math.max(1, Theme.u / 2)

    // the cover
    Rectangle {
        anchors.fill: parent
        radius: Theme.u * 2
        color: "#1f3326"
        border.width: Math.max(2, Theme.u)
        border.color: "#0f1a13"
    }
    // brass corners
    Repeater {
        model: 4
        PxIcon {
            required property int index
            z: 2
            bitmap: ["yyyyyy", "yy#yy.", "y#yy..", "yyy...", "yy....", "y....."]
            pixel: Math.max(1, Theme.u)
            ink: "#7a5a1a"
            fill3: "#c9a24a"
            rotation: index * 90
            x: index === 1 || index === 2 ? dress.width - width - Theme.u : Theme.u
            y: index >= 2 ? dress.height - height - Theme.u : Theme.u
        }
    }
    // the totals: a narrow ruled column beside the page
    Rectangle {
        id: totals
        x: dress.width - dress.pageRight + Theme.u * 4
        y: dress.pageTop
        width: dress.pageRight - Theme.u * 12
        height: dress.height - dress.pageTop - dress.pageBottom
        color: dress.paper
        border.width: Math.max(1, Theme.u / 2)
        border.color: "#9fb39a"
        Repeater {
            model: Math.max(0, Math.floor((totals.height - Theme.u * 30) / (Theme.u * 9)))
            Rectangle {
                required property int index
                x: Theme.u * 2
                y: Theme.u * 10 + index * Theme.u * 9
                width: totals.width - Theme.u * 4
                height: Math.max(1, Theme.u / 2)
                color: Qt.alpha("#4f7a5a", 0.35)
            }
        }
        // the double red rule of the account
        Repeater {
            model: 2
            Rectangle {
                required property int index
                x: Theme.u * (3 + index * 2)
                y: 0
                width: Math.max(1, Theme.u / 2)
                height: totals.height
                color: Qt.alpha(dress.redInk, 0.6)
            }
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.u * 2
            kind: "tiny"
            color: dress.ink
            text: I18n.t("ИТОГ", "TOTAL")
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.u * 4
            kind: "mono"
            font.bold: true
            color: dress.redInk
            text: "−∞"
        }
    }
    // a stack of coins on the cover
    PxIcon {
        z: 2
        bitmap: [".yyyy.", "yyyyyy", "#yyyy#", ".####.", ".yyyy.", "yyyyyy", "#yyyy#", ".####.", ".yyyy.", "yyyyyy", "#yyyy#", ".####."]
        pixel: Math.max(1, Theme.u)
        ink: "#7a5a1a"
        fill3: "#d8b862"
        x: totals.x + (totals.width - width) / 2
        y: totals.y + totals.height - height - Theme.u * 18
    }
}
