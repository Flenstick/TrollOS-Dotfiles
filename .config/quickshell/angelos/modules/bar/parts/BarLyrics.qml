import QtQuick
import qs.config
import qs.services
import qs.widgets

// Current lyric line on the bar: typewriter reveal, old line slides away.
// The box is as wide as the song's longest line (up to maxWidth), so it stays
// put during a song; a line that still doesn't fit glides sideways instead of
// being cut. Left click: Lyrics settings, right click: pause / play.
Item {
    id: root

    required property string screenName
    property real maxWidth: Theme.u * 250
    property bool fixedWidth: false        // keep one width per song so the bar doesn't jump
    readonly property bool onThisScreen: !Config.lyrics.screens || Config.lyrics.screens.length === 0 || Config.lyrics.screens.includes(screenName)
    readonly property bool lyricsMode: Lyrics.visibleToggle && Lyrics.hasLyrics
    // with the island plugin the line never hides: lyrics → track → the plugin's idle text
    readonly property var hook: Shell.lyricsHook
    readonly property bool active: Config.lyrics.enabled && onThisScreen && (lyricsMode || !!hook)
    readonly property string idleLine: {
        if (Lyrics.title !== "")
            return Lyrics.artist !== "" ? Lyrics.artist + " — " + Lyrics.title : Lyrics.title;
        return hook && hook.idleText ? hook.idleText : "♪ ~ ♪";
    }
    readonly property string line: lyricsMode ? (Lyrics.current !== "" ? Lyrics.current : "♪ ~ ♪") : idleLine
    readonly property real chrome: note.width + Theme.u * 6

    // widest line of the current song, measured once per song
    property real songText: 0
    function measureSong() {
        let w = fm.advanceWidth("♪ ~ ♪");
        for (const l of Lyrics.lines)
            w = Math.max(w, fm.advanceWidth(l.text || ""));
        songText = Math.ceil(w);
    }
    Connections {
        target: Lyrics
        function onLinesChanged() {
            root.measureSong();
        }
    }
    FontMetrics {
        id: fm
        font.family: Theme.fontBody
        font.pixelSize: Theme.sizeBody
        font.hintingPreference: Font.PreferFullHinting
        onFontChanged: root.measureSong()
    }

    visible: active && maxWidth >= Theme.u * 50
    implicitWidth: Math.min(maxWidth, (fixedWidth && lyricsMode ? songText : fullW) + chrome)
    implicitHeight: Theme.u * 13
    clip: true

    readonly property bool coverReady: cover.status === Image.Ready
    property string shown: ""
    property string previous: ""
    property int typed: 0
    readonly property real fullW: fm.advanceWidth(shown)
    readonly property real typedW: typed >= shown.length ? fullW : fm.advanceWidth(shown.slice(0, typed))
    readonly property real overflowW: Math.max(0, fullW - textBox.width)
    property real scrollX: 0

    onLineChanged: {
        previous = shown;
        shown = line;
        glide.stop();
        scrollX = 0;
        if (!Config.lyrics.typewriter) {
            typed = shown.length;
            startGlide();
        } else {
            typed = 0;
            const dur = Math.max(0.3, Lyrics.lineEnd - Lyrics.lineStart);
            typer.interval = Math.max(12, Math.min(38, dur * 1000 * 0.45 / Math.max(1, shown.length)));
            typer.restart();
        }
        slide.restart();
    }
    Component.onCompleted: {
        Shell.lyricsItems[screenName] = root;
        shown = line;
        typed = shown.length;
        measureSong();
    }
    // long line: read the start, then glide to the end within the line's time
    function startGlide() {
        if (overflowW <= 0)
            return;
        const dur = Math.max(1.2, Lyrics.lineEnd - Lyrics.lineStart);
        glideMove.to = overflowW;
        glideMove.duration = Math.max(900, Math.min(8000, dur * 1000 * 0.55));
        glide.restart();
    }

    Timer {
        id: typer
        repeat: true
        onTriggered: {
            root.typed = Math.min(root.shown.length, root.typed + 1);
            if (root.typed >= root.shown.length) {
                stop();
                // the caret already pulled the text to its end
                root.scrollX = root.overflowW;
            }
        }
    }
    SequentialAnimation {
        id: glide
        PauseAnimation {
            duration: 700
        }
        NumberAnimation {
            id: glideMove
            target: root
            property: "scrollX"
            easing.type: Easing.InOutSine
        }
    }

    Item {
        id: note
        width: Config.lyrics.artwork === "cover" ? Theme.u * 12 : Theme.u * 8
        height: Theme.u * 12
        anchors.verticalCenter: parent.verticalCenter
        // note + text centred as one piece
        x: Math.max(0, Math.round((root.width - root.chrome - Math.min(root.fullW, root.width - root.chrome)) / 2))
        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        opacity: Lyrics.playing ? 1 : 0.6
        Image {
            id: cover
            anchors.fill: parent
            source: Config.lyrics.artwork === "cover" ? Lyrics.artUrl : ""
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
            clip: true
        }
        PxIcon {
            anchors.centerIn: parent
            name: !Lyrics.player ? "pill" : Lyrics.playing ? "music" : "pause"
            visible: cover.status !== Image.Ready || !Lyrics.playing
            pixel: Math.max(1, Theme.u - 1)
        }
    }

    Item {
        id: textBox
        anchors.left: note.right
        anchors.leftMargin: Theme.u * 4
        anchors.right: parent.right
        anchors.rightMargin: Theme.u * 2
        height: parent.height
        clip: true

        // previous line sliding up and out
        PxText {
            id: old
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            text: root.previous
            elide: Text.ElideRight
            color: Theme.textDim
            opacity: 0
        }
        PxText {
            id: cur
            width: Math.max(parent.width, root.fullW + Theme.u * 4)
            // while typing, the caret pulls a long line along; afterwards scrollX holds / glides
            x: typer.running ? -Math.max(0, root.typedW + Theme.u * 3 - textBox.width) : -Math.min(root.scrollX, root.overflowW)
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.StyledText
            color: (root.lyricsMode && Lyrics.current === "") || !Lyrics.playing ? Theme.textDim : Theme.text
            text: {
                const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
                const t = root.shown;
                return esc(t.slice(0, root.typed)) + (root.typed < t.length ? "<font color='" + Theme.hex(Theme.accent) + "'>▌</font>" : "");
            }
        }

        ParallelAnimation {
            id: slide
            NumberAnimation {
                target: old
                property: "anchors.verticalCenterOffset"
                from: 0
                to: -Theme.u * 8
                duration: 220
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: old
                property: "opacity"
                from: 0.8
                to: 0
                duration: 220
            }
            NumberAnimation {
                target: cur
                property: "anchors.verticalCenterOffset"
                from: Theme.u * 6
                to: 0
                duration: 180
                easing.type: Easing.OutBack
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: !!root.hook
        onContainsMouseChanged: if (root.hook && root.hook.warm)
            root.hook.warm(root.screenName, containsMouse)
        onClicked: m => {
            if (m.button === Qt.RightButton) {
                if (Lyrics.player && Lyrics.player.canTogglePlaying)
                    Lyrics.player.togglePlaying();
            } else if (Shell.lyricsHook)
                Shell.lyricsHook.toggle(root, root.screenName);
            else
                Shell.openSettings("lyrics");
        }
    }
    // the island (dynamic-island plugin) grows out of this line
    Component.onDestruction: {
        if (Shell.lyricsItems[screenName] === root)
            delete Shell.lyricsItems[screenName];
    }
}
