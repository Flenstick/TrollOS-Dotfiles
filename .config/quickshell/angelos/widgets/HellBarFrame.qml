pragma ComponentBehavior: Bound

import QtQuick
import qs.config

// A bar in hell, any style: the circle's ground (HellTexture) where nothing is, a calm
// plate (Theme.hellPlate) under every run of widgets — text and icons never sit on the
// pattern — and a thin rim on the side that faces the desktop instead of flames. Still;
// nothing over the windows, nothing over the bar's own buttons.
//   content  the BarContent whose `hellPlates` (its runs of widgets) get the plates
//   rim      "top" | "bottom" | "all" — where the rim runs
Item {
    id: root

    property Item content: null
    property string rim: "top"
    property bool texture: true

    // the plates in this item's coordinates (they follow the content as it moves)
    readonly property var plates: {
        const c = root.content;
        if (!c || !c.hellPlates)
            return [];
        const deps = [c.x, c.y, c.width, root.x, root.y, root.width];
        return c.hellPlates.map(r => {
            const p = c.mapToItem(root, r.x, r.y);
            return {
                "x": Math.round(p.x / Theme.u) * Theme.u,
                "y": Math.round(p.y / Theme.u) * Theme.u,
                "w": Math.round(r.w / Theme.u) * Theme.u,
                "h": Math.round(r.h / Theme.u) * Theme.u
            };
        });
    }

    HellTexture {
        visible: root.texture
        anchors.fill: parent
    }
    // no texture (a capsule is all plate): the plate's colour all over
    Rectangle {
        visible: !root.texture
        anchors.fill: parent
        color: Theme.hellPlate
    }

    Repeater {
        model: root.plates
        Rectangle {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
            color: Theme.hellPlate
            border.width: Math.max(1, Theme.u / 2)
            border.color: Theme.hellEdge
        }
    }

    // the rim: a dark line on the outside, the circle's rim colour inside it
    Rectangle {
        visible: root.rim === "top" || root.rim === "all"
        width: parent.width
        height: Theme.u
        color: Theme.hellEdge
        Rectangle {
            y: parent.height
            width: parent.width
            height: Theme.u
            color: Theme.hellRim
        }
    }
    Rectangle {
        visible: root.rim === "bottom" || root.rim === "all"
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.u
        color: Theme.hellEdge
        Rectangle {
            y: -height
            width: parent.width
            height: Theme.u
            color: Theme.hellRim
        }
    }
    Repeater {
        model: root.rim === "all" ? [0, 1] : []
        Rectangle {
            id: side
            required property int index
            x: index === 0 ? 0 : root.width - width
            width: Theme.u
            height: root.height
            color: Theme.hellEdge
            Rectangle {
                x: side.index === 0 ? parent.width : -width
                y: Theme.u
                width: Theme.u
                height: parent.height - Theme.u * 2
                color: Theme.hellRim
            }
        }
    }
}
