pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// power-profiles-daemon over D-Bus: reacts to changes from anywhere (powerprofilesctl, gamemode…)
Singleton {
    id: root

    readonly property var modes: [
        {
            "id": "power-saver",
            "value": PowerProfile.PowerSaver,
            "name": "Энергосбережение",
            "hint": "тише и холоднее",
            "bitmap": ["......#####", "....##xxxx#", "...#xxxxxx#", "..#xxxxx#x#", "..#xxxx#xx#", "..#xx#xxx#.", "..#x#xxx#..", "..##xxx##..", ".#.####....", "#.........."]
        },
        {
            "id": "balanced",
            "value": PowerProfile.Balanced,
            "name": "Баланс",
            "hint": "обычный режим",
            "bitmap": ["....###....", ".#########.", ".#...#...#.", "#o#..#..#o#", "###..#..###", ".....#.....", ".....#.....", "...#####..."]
        },
        {
            "id": "performance",
            "value": PowerProfile.Performance,
            "name": "Производительность",
            "hint": "максимум для игр",
            "bitmap": [".....####", "....#yy#.", "...#yy#..", "..#yy####", ".#yyyyy#.", "####yy#..", "...#y#...", "..#y#....", "..##....."]
        }
    ]
    readonly property var available: modes.filter(m => m.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)
    readonly property int index: Math.max(0, available.findIndex(m => m.value === PowerProfiles.profile))
    readonly property var current: available[index]
    readonly property string degraded: PowerProfiles.degradationReason !== PerformanceDegradationReason.None ? PerformanceDegradationReason.toString(PowerProfiles.degradationReason) : ""

    signal menuRequested

    function set(id) {
        const m = available.find(x => x.id === id);
        if (!m)
            return false;
        PowerProfiles.profile = m.value;
        return true;
    }
    // step > 0 → faster, step < 0 → greener; stops at the ends
    function step(dir) {
        const i = Math.min(available.length - 1, Math.max(0, index + dir));
        PowerProfiles.profile = available[i].value;
    }
    function cycle() {
        PowerProfiles.profile = available[(index + 1) % available.length].value;
    }
}
