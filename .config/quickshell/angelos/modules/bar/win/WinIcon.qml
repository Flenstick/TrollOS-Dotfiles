import QtQuick
import qs.services

// A Fluent UI System Icon from ./icons. tone: auto (white in dark mode,
// near-black in light), white or black (on accent fills).
Image {
    property string name: ""
    property int size: 16
    property string tone: "auto"
    readonly property bool white: tone === "auto" ? WinStyle.dark : tone === "white"
    width: size
    height: size
    source: name ? Qt.resolvedUrl("icons/" + (white ? "d/" : "l/") + name + ".svg") : ""
    sourceSize: Qt.size(size * 2, size * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
