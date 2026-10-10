import QtQuick
import qs.config

// The home of the Windose and Stream looks (Classic opens your account instead).
Loader {
    id: root
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    source: "DlcHomePage.qml"
}
