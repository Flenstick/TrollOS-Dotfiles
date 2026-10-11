pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// TrollOS: live wallpapers drawn by a shader (the desktop layouts' «animated wallpaper»). Each
// is data/wallshaders/<id>.frag.qsb (sources in src/, build.sh) with its still: stills/<id>.jpg
// is the shader's frame at time 0, so nothing jumps when the layer comes and goes. While a
// screen shows a still and Config.wallpaper.shaders is on, its shader plays in the wallpaper's
// slot (Shell.wallpaperSlots, between the picture and the widgets). Time runs only while that
// desk has no windows, the screen isn't locked and has no fullscreen window, and no eco mode:
// in a game the layer stands still and the GPU is left alone.
//   `qs -c angelos ipc call wallshader status|summon|fps <n>`
Item {
    id: root

    readonly property string dir: Quickshell.shellDir + "/data/wallshaders"
    // id -> the pictures that stand for it: its still, and older names of the same frame
    // (the hell-nebula plugin's own picture, while that plugin is off)
    readonly property var walls: ({
            "nebula": ["Hell Nebula 4K.png"],
            "vampire": [],
            "void": [],
            "material": []
        })
    // shaders that take the scheme's colours (c0…c4): their still can't stand in for them, so the
    // layer stays even with the animation off (frozen, nothing runs)
    readonly property var dynamic: ["material"]
    readonly property bool on: Config.ready && Config.wallpaper.shaders
    readonly property bool paused: Motion.still || Power.eco
    readonly property int fps: Math.max(5, Math.min(120, Config.wallpaper.shaderFps || 30))

    readonly property bool nebulaPlugin: {
        const p = Plugins.byId("hell-nebula");
        return !!p && Plugins.isEnabled(p);
    }

    function still(id) {
        return dir + "/stills/" + id + ".jpg";
    }
    // the shader a wallpaper path stands for, "" for an ordinary picture
    function shaderFor(path) {
        if (!path)
            return "";
        const name = String(path).replace(/^.*\//, "");
        for (const id of Object.keys(walls)) {
            if (path === still(id))
                return id;
            // the hell-nebula plugin draws its own picture itself: never twice
            if (walls[id].includes(name) && !(id === "nebula" && nebulaPlugin))
                return id;
        }
        return "";
    }

    signal summon

    IpcHandler {
        target: "wallshader"
        function summon(): void {
            root.summon();
        }
        function fps(n: int): void {
            Config.wallpaper.shaderFps = Math.max(5, Math.min(120, n));
        }
        function status(): string {
            return JSON.stringify({
                "on": root.on,
                "paused": root.paused,
                "fps": root.fps,
                "screens": Quickshell.screens.map(s => {
                    const ws = Niri.activeWorkspace(s.name);
                    return s.name + ": " + (root.shaderFor(Wallpapers.resolve(s.name, ws ? ws.idx : 1)) || "-");
                })
            });
        }
    }

    Variants {
        model: Quickshell.screens

        Item {
            id: win
            required property var modelData
            readonly property string name: modelData.name
            readonly property var ws: Niri.activeWorkspace(name)
            readonly property Item slot: Shell.wallpaperSlots[name] || null
            readonly property string matched: slot && Config.ready ? root.shaderFor(Wallpapers.resolve(name, ws ? ws.idx : 1)) : ""
            readonly property string shader: matched !== "" && (root.on || root.dynamic.includes(matched)) ? matched : ""
            readonly property bool running: shader !== "" && root.on && !root.paused && !!ws && Niri.windowsOn(ws.id).length === 0 && !Shell.locked && !Shell.fullscreenOn(name)

            parent: slot
            anchors.fill: parent
            visible: shader !== ""

            ShaderEffect {
                id: fx
                anchors.fill: parent
                property real time: 0
                property size size: Qt.size(width, height)
                property real glow: 0
                // the Material You wallpaper's colours (others ignore them)
                property color c0: Theme.md.surface
                property color c1: Theme.md.primaryContainer
                property color c2: Theme.md.tertiaryContainer
                property color c3: Theme.md.secondaryContainer
                property color c4: Theme.md.primary
                // an absolute file:// path: a relative one gave an empty frame here
                fragmentShader: win.shader ? "file://" + root.dir + "/" + win.shader + ".frag.qsb" : ""

                SequentialAnimation on glow {
                    id: flare
                    running: false
                    NumberAnimation {
                        to: 1
                        duration: 450
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        to: 0
                        duration: 2600
                        easing.type: Easing.InOutSine
                    }
                }
            }
            // a new shader starts from its still
            onShaderChanged: fx.time = 0
            Timer {
                interval: Math.round(1000 / root.fps)
                running: win.running
                repeat: true
                property double last: 0
                onRunningChanged: last = 0
                onTriggered: {
                    const now = Date.now();
                    if (last)
                        fx.time += Math.min(0.25, (now - last) / 1000);
                    last = now;
                }
            }
            Connections {
                target: root
                function onSummon() {
                    if (win.shader)
                        flare.restart();
                }
            }
        }
    }
}
