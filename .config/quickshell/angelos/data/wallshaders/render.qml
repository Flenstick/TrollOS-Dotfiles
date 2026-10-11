// TrollOS: a frame of a live wallpaper as a picture (the still that stands in for it):
//   SHADER=vampire OUT=x.png W=3840 H=2160 T=0 qs -p render.qml   (render.sh does it)
import QtQuick
import Quickshell
import Quickshell.Wayland
ShellRoot {
    PanelWindow {
        id: win
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "wallshader-render"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true }
        implicitWidth: 64; implicitHeight: 64
        color: "transparent"
        mask: Region {}
        // an absolute file:// path: the resolved URL gave ShaderEffect an empty frame
        readonly property string src: "file://" + Quickshell.env("SHADER_DIR") + "/" + Quickshell.env("SHADER") + ".frag.qsb"
        // visible but all but transparent: without it Qt never prepares the shader and the grab is empty
        ShaderEffect {
            anchors.fill: parent
            opacity: 0.0001
            property real time: 0
            property size size: Qt.size(width, height)
            property real glow: 0
            property color c0: Quickshell.env("C0") || "#141218"
            property color c1: Quickshell.env("C1") || "#4f378b"
            property color c2: Quickshell.env("C2") || "#633b48"
            property color c3: Quickshell.env("C3") || "#4a4458"
            property color c4: Quickshell.env("C4") || "#d0bcff"
            fragmentShader: win.src
        }
        ShaderEffect {
            id: fx
            visible: false
            width: Number(Quickshell.env("W") || 3840)
            height: Number(Quickshell.env("H") || 2160)
            property real time: Number(Quickshell.env("T") || 0)
            property size size: Qt.size(width, height)
            property real glow: 0
            // the Material You wallpaper's scheme colours (C0…C4: surface, primary/tertiary/
            // secondary containers, primary)
            property color c0: Quickshell.env("C0") || "#141218"
            property color c1: Quickshell.env("C1") || "#4f378b"
            property color c2: Quickshell.env("C2") || "#633b48"
            property color c3: Quickshell.env("C3") || "#4a4458"
            property color c4: Quickshell.env("C4") || "#d0bcff"
            fragmentShader: win.src
        }
        Timer {
            interval: 900; running: true
            onTriggered: fx.grabToImage(r => { r.saveToFile(Quickshell.env("OUT")); Qt.quit(); })
        }
    }
}
