import QtQuick
import qs.config
import "A11y.js" as A11y
import "MaterialIcons.js" as MaterialIcons

// Menu row: icon + label (+ optional hint / submenu arrow). separator: true draws a line.
Item {
    id: root

    property string text: ""
    property string icon: ""
    property string hint: ""
    property bool separator: false
    property bool submenu: false
    property bool checked: false
    property bool checkable: false
    property bool highlighted: false        // keyboard selection
    property string skin: ""                // "" | y2k (glossy pill highlight, rainbow lines)
    property real iconScale: 1              // bigger or smaller icons (Start → Fine-tune → Icons)
    readonly property bool hovered: mouse.containsMouse
    readonly property bool lit: (mouse.containsMouse || highlighted) && enabled
    // TrollOS: the «Material You» skin — Material 3's menu item: 48 dp, a symbol, a state layer
    readonly property bool md: skin !== "y2k" && Theme.settingsSkinFor(root) === "material"
    readonly property string mdIcon: md ? MaterialIcons.fromPixel(checkable ? (checked ? "check" : "") : icon) : ""
    signal triggered

    Accessible.role: Accessible.MenuItem
    Accessible.name: A11y.name(text, root, icon)
    Accessible.description: hint
    Accessible.checked: checked
    Accessible.onPressAction: if (enabled)
        triggered()

    width: parent ? parent.width : implicitWidth
    implicitWidth: separator ? Theme.u * 20 : row.implicitWidth + hintText.implicitWidth + Theme.u * 24
    implicitHeight: md ? Theme.mdPx(separator ? 17 : 48) : separator ? Theme.u * 5 : Theme.sizeBody + Theme.u * 8
    opacity: enabled ? 1 : 0.45

    // y2k: a rainbow line
    Rectangle {
        visible: root.separator && root.skin === "y2k"
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.u * 4
        width: parent.width - Theme.u * 8
        height: Math.max(1, Theme.u / 2)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.2
                color: "#ff6fb0"
            }
            GradientStop {
                position: 0.5
                color: "#ffe066"
            }
            GradientStop {
                position: 0.8
                color: "#8fe3ff"
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }
    Rectangle {
        visible: root.separator && root.md
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 1
        color: Theme.md.outlineVariant
    }
    Rectangle {
        visible: !root.separator && root.md
        anchors.fill: parent
        anchors.leftMargin: Theme.mdPx(4)
        anchors.rightMargin: Theme.mdPx(4)
        radius: Theme.mdRadius("s")
        color: Theme.md.onSurface
        opacity: mouse.pressed ? 0.12 : root.lit ? 0.08 : 0
    }
    Rectangle {
        visible: root.separator && root.skin !== "y2k" && !root.md
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.u * 2
        width: parent.width - Theme.u * 4
        height: Math.max(1, Theme.u / 2)
        color: Theme.lo
        Rectangle {
            y: parent.height
            width: parent.width
            height: parent.height
            color: Theme.hi
        }
    }

    Rectangle {
        visible: !root.separator && root.skin !== "y2k" && !root.md
        anchors.fill: parent
        color: root.lit ? Theme.select : "transparent"
    }
    // y2k: a glossy pill
    Rectangle {
        visible: !root.separator && root.skin === "y2k" && root.lit
        anchors.fill: parent
        anchors.leftMargin: Theme.u * 2
        anchors.rightMargin: Theme.u * 2
        anchors.topMargin: Theme.u / 2
        anchors.bottomMargin: Theme.u / 2
        radius: height / 2
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.mix(Theme.accent, "#ffffff", 0.45)
            }
            GradientStop {
                position: 0.5
                color: Theme.accent
            }
            GradientStop {
                position: 1
                color: Theme.mix(Theme.accent, Theme.edge, 0.2)
            }
        }
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha("#ffffff", 0.6)
        Rectangle {
            x: parent.radius / 2
            y: Math.max(1, Theme.u / 2)
            width: parent.width - parent.radius
            height: parent.height * 0.42
            radius: height / 2
            color: Qt.alpha("#ffffff", 0.35)
        }
    }

    Row {
        id: row
        visible: !root.separator
        anchors.left: parent.left
        anchors.leftMargin: root.md ? Theme.mdPx(16) : Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.md ? Theme.mdPx(12) : Theme.u * 4
        Item {
            width: root.md ? Theme.mdPx(24) : Math.round(Theme.u * 12 * root.iconScale)
            height: root.md ? Theme.mdPx(24) : Math.round(Theme.u * 11 * root.iconScale)
            anchors.verticalCenter: parent.verticalCenter
            MdSymbol {
                visible: root.mdIcon !== ""
                anchors.centerIn: parent
                name: root.mdIcon
                size: Theme.mdPx(22)
                color: Theme.md.onSurfaceVariant
            }
            PxIcon {
                anchors.centerIn: parent
                opacity: root.mdIcon === "" ? 1 : 0
                exactPixel: root.iconScale !== 1 ? Theme.u * root.iconScale : 0
                visible: root.icon !== "" || (root.checkable && root.checked)
                name: root.checkable ? (root.checked ? "check" : "heart") : (root.icon || "heart")
                ink: root.lit ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
            }
        }
        PxText {
            text: root.text
            color: root.md ? Theme.md.onSurface : root.lit ? Theme.selectText : Theme.text
            anchors.verticalCenter: parent.verticalCenter
            // never under the hint (bigger fonts, a narrow menu): it elides instead
            width: Math.max(0, Math.min(implicitWidth, root.width - x - row.anchors.leftMargin - (hintText.visible ? hintText.implicitWidth + Theme.u * 9 : Theme.u * 5)))
            elide: Text.ElideRight
        }
    }
    PxText {
        id: hintText
        visible: !root.separator && (root.hint !== "" || root.submenu)
        text: root.submenu ? (root.skin === "y2k" ? "✦" : root.md ? "›" : "▸") : root.hint
        dim: !root.lit
        color: root.md ? Theme.md.onSurfaceVariant : root.lit ? Theme.selectText : Theme.textDim
        anchors.right: parent.right
        anchors.rightMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouse
        visible: !root.separator
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
