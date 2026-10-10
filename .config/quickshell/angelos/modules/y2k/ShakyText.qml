import QtQuick
import qs.config
import qs.widgets

// Undertale-style speech for the corner helper: every letter on its own, laid
// out once for the whole line (the bubble doesn't grow while she types), shown
// up to `shown`, and now and then a letter twitches by a pixel — only a few at
// a time, so the line stays readable. `twitch` is the share of letters off
// their place at any moment (AngelHelper: Y2K → Text tremble).
Flow {
    id: root

    property string text: ""
    property int shown: text.length
    property real shake: 1                   // px, one way
    property real twitch: 0.06               // 0 = still
    property int tick: 0
    property color color: Theme.text

    Timer {
        interval: 120
        repeat: true
        running: root.visible && root.twitch > 0 && root.text !== ""
        onTriggered: root.tick++
    }
    // words with their trailing spaces, so the line wraps between words only
    readonly property var words: {
        const out = [];
        const re = /\S+\s*|\s+/g;
        let m;
        while ((m = re.exec(text)) !== null)
            out.push({
                "w": m[0],
                "at": m.index
            });
        return out;
    }
    function rnd(at, salt) {
        const v = Math.sin((at + 1) * 12.9898 + (tick + salt) * 78.233) * 43758.5453;
        return v - Math.floor(v);
    }
    // a pixel up, down, left or right for the few letters whose turn it is; 0 for the rest
    function nudge(at, axis) {
        if (twitch <= 0 || rnd(at, 5) >= twitch)
            return 0;
        const dir = Math.floor(rnd(at, 11) * 4);
        return axis === 0 ? (dir === 0 ? -1 : dir === 1 ? 1 : 0) : (dir === 2 ? -1 : dir === 3 ? 1 : 0);
    }

    Repeater {
        model: root.words
        Row {
            id: word
            required property var modelData
            Repeater {
                model: word.modelData.w.length
                PxText {
                    id: letter
                    required property int index
                    readonly property int at: word.modelData.at + index
                    text: word.modelData.w.charAt(index)
                    color: root.color
                    opacity: at < root.shown ? 1 : 0
                    transform: Translate {
                        x: root.nudge(letter.at, 0) * root.shake
                        y: root.nudge(letter.at, 1) * root.shake
                    }
                }
            }
        }
    }
}
