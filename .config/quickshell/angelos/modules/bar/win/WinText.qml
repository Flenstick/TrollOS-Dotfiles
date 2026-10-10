import QtQuick
import qs.services

// Text in the Windows 11 type ramp (Segoe UI when installed).
Text {
    property bool strong: false
    font.family: WinStyle.font
    font.pixelSize: WinStyle.body
    font.weight: strong ? Font.DemiBold : Font.Normal
    color: WinStyle.text
    renderType: Text.NativeRendering
    elide: Text.ElideRight
    maximumLineCount: 1
    verticalAlignment: Text.AlignVCenter
}
