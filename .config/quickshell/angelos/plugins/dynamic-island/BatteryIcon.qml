import QtQuick
import qs.widgets

// Батарейка на 8 делений: красная когда мало, жёлтая на зарядке.
PxIcon {
    id: root

    property int level: -1
    property bool charging: false
    readonly property int cells: level < 0 ? 0 : Math.max(level > 0 ? 1 : 0, Math.round(level / 12.5))
    readonly property string cell: charging ? "y" : level <= 20 ? "r" : "o"
    readonly property string mid: "#" + cell.repeat(cells) + ".".repeat(8 - cells) + "##"

    bitmap: Array.from(["##########.", mid, mid, mid, "##########."])
}
