import QtQuick
import QtMultimedia

// Looping video for an overlay item. Loaded through a Loader by URL so the shell
// still starts when QtMultimedia is missing.
Item {
    id: root

    property string path: ""
    property bool muted: true
    property bool paused: false
    readonly property real ratio: player.metaData.value(MediaMetaData.Resolution) ? player.metaData.value(MediaMetaData.Resolution).width / Math.max(1, player.metaData.value(MediaMetaData.Resolution).height) : 0
    readonly property bool failed: player.error !== MediaPlayer.NoError

    MediaPlayer {
        id: player
        source: root.path ? "file://" + root.path : ""
        loops: MediaPlayer.Infinite
        videoOutput: out
        audioOutput: AudioOutput {
            muted: root.muted
        }
        Component.onCompleted: if (!root.paused)
            play()
    }
    onPausedChanged: paused ? player.pause() : player.play()

    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }
}
