pragma Singleton

import QtQuick
import Quickshell

// Hell's screen effects that are not the helper's own (modules/y2k/HellFxOverlay draws them,
// only while the demon rules and only off the stream when its effects are hidden):
//   fireworks(screen, x, y, fromTop) — the lyrics' salute when a song ends (BarLyrics),
//                                      from that point, upwards (downwards for a top bar)
//   cerberus(screen)                 — the puppy runs across the screen (the Wheel of Hell)
Singleton {
    signal fireworks(string screen, real x, real y, bool fromTop)
    signal cerberus(string screen)
}
