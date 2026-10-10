import QtQuick
import qs.config

// Every section as tiles, in the Windose and Stream looks.
Loader {
    id: root
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    source: "DlcMorePage.qml"
}
