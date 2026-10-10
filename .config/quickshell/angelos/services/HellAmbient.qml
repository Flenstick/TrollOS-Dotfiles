pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Hell's one moving thing: now and then — every few minutes, at random — something slow
// happens, either on the rim of one window or widget (HellLook.event: an ember glows and
// dies, rime creeps, a drop falls; widgets/HellEdge draws it) or on the ground — the
// circle's ambient over the wallpaper (eventTarget -2: the fog drifts, the rain falls,
// something moves under the Styx, eyes open in the pitch; shaders/hell_backdrop.frag).
// Nothing at all while a window covers a screen (games, video: the same moment
// niri-game-mode turns animations off), while streaming, locked, or out of hell; limbo
// and Cocytus barely stir. In between, no timer ticks.
Singleton {
    id: root

    readonly property bool allowed: Angel.demon && !Motion.still && !Shell.locked && !StreamMode.active && !Shell.screens.some(s => Shell.fullscreenOn(s.name))
    readonly property int durationMs: 4200

    function schedule() {
        // the still circles wait longer
        const still = HellLook.circle === "treachery" || HellLook.circle === "limbo";
        wait.interval = (150 + Math.random() * 210) * 1000 * (still ? 2 : 1);
        wait.restart();
    }
    // `angelos helper ambient` (dev or owner): one now, to see it
    function now() {
        start();
    }
    function start() {
        HellLook.eventTarget = HellLook.ambient && Math.random() < 0.5 ? -2 : Math.floor(Math.random() * 6);
        root._t0 = Date.now();
        HellLook.event = 0;
        HellLook.phase = 0;
        tick.start();
    }
    property double _t0: 0

    onAllowedChanged: {
        if (allowed)
            schedule();
        else {
            wait.stop();
            tick.stop();
            HellLook.event = 0;
            HellLook.eventTarget = -1;
        }
    }
    Component.onCompleted: if (allowed)
        schedule()

    Timer {
        id: wait
        onTriggered: if (root.allowed)
            root.start()
    }
    // ten steps a second while it lasts: up, hold, down — stepped, like everything pixel
    Timer {
        id: tick
        interval: 100
        repeat: true
        onTriggered: {
            const p = (Date.now() - root._t0) / root.durationMs;
            if (p >= 1) {
                stop();
                HellLook.event = 0;
                HellLook.phase = 0;
                HellLook.eventTarget = -1;
                root.schedule();
                return;
            }
            const v = p < 0.35 ? p / 0.35 : p < 0.6 ? 1 : (1 - p) / 0.4;
            HellLook.event = Math.round(v * 8) / 8;
            HellLook.phase = Math.round(p * 40) / 40;
        }
    }
}
