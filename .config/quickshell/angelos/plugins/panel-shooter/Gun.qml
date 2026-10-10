pragma Singleton

import QtQuick

// Shared state of the shooting range: the bar button, its popup and the
// overlay in Main.qml all read and drive this one object.
QtObject {
    id: gun

    property bool armed: false
    // the Geiger counter from the same case (Geiger.qml); one thing in hand at a time
    property bool geiger: false
    onArmedChanged: if (armed)
        geiger = false
    onGeigerChanged: if (geiger)
        armed = false
    readonly property int magSize: 7
    property int ammo: magSize
    property bool reloading: false
    property real lastShot: 0

    // this session
    property int shots: 0
    property int hits: 0
    property int kills: 0
    // all time (Main.qml keeps them in the plugin settings)
    property int totalKills: 0
    property int totalHeadshots: 0

    signal waveRequested(int count)
    signal statsReset

    // Other plugins (friend-runner) register targets here. A target is a
    // function (screenX, pixelsFromScreenBottom) -> null | {head, name}; it
    // plays its own death when it returns a hit.
    property var targets: []
    function register(fn) {
        targets = targets.concat([fn]);
    }
    function unregister(fn) {
        targets = targets.filter(t => t !== fn);
    }
    function hitTest(x, fromBottom) {
        for (const t of targets) {
            const r = t(x, fromBottom);
            if (r)
                return r;
        }
        return null;
    }

    // The torture room (plugin torture-room) sets `chamber` while it is on.
    // A runner plugin hands a person over with grab(); when the room lets
    // them go it emits victimReleased and the owner makes them run away.
    // victim: {owner, kind: "random"|"friend", name, beloved, sx, sy (screen
    // point under their feet), and the looks: hair/shirt/pants/skin or avatar}
    property bool chamber: false
    property var victim: null
    signal victimReleased(var victim, var info)    // info: {x (screen), broken}
    function grab(v) {
        if (!chamber || victim)
            return false;
        victim = v;
        return true;
    }
    function release(info) {
        const v = victim;
        victim = null;
        if (v)
            victimReleased(v, info || {});
    }

    function take() {
        armed = true;
    }
    function holster() {
        armed = false;
    }
    function toggle() {
        armed = !armed;
    }
    function toggleGeiger() {
        geiger = !geiger;
    }
}
