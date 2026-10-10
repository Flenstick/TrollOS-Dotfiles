import QtQuick
import qs.config
import qs.services

// Text with pixel-font defaults. kind: tiny | body | title | big | huge | mono
Text {
    property string kind: "body"
    property bool dim: false
    // inside the Windows 11 styled Settings window: Segoe / Noto type ramp
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    color: fluent ? (dim ? WinStyle.text2 : WinStyle.text) : dim ? Theme.textDim : Theme.text
    font.family: fluent ? (kind === "mono" ? "monospace" : WinStyle.font) : kind === "body" ? Theme.fontBody : kind === "mono" ? Theme.fontMono : Theme.fontTitle
    font.pixelSize: fluent ? (kind === "tiny" ? 12 : kind === "title" ? 20 : kind === "big" ? 28 : kind === "huge" ? 40 : 14) : kind === "tiny" ? Theme.sizeTiny : kind === "mono" ? Theme.sizeMono : kind === "title" ? Theme.sizeTitle : kind === "big" ? Theme.sizeBig : kind === "huge" ? Theme.sizeHuge : Theme.sizeBody
    font.weight: fluent && (kind === "title" || kind === "big" || kind === "huge") ? Font.DemiBold : Font.Normal
    font.hintingPreference: Font.PreferFullHinting
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    // AutoText would render HTML found in window titles, track names or the
    // clipboard (<img src=…> even fetches remote images). Opt in per use.
    textFormat: Text.PlainText
}
