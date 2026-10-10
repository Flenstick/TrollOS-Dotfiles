import QtQuick
import Quickshell
import qs.services

// Night light: a warmer screen in the evening. The gamma tables are angelOS's own
// (services/ScreenTune → scripts/gamma.py), shared with the brightness sliders in
// Settings → Monitor: one owner, so no wlsunset next to them.
Item {
    id: root
    property var plugin
    readonly property bool wanted: !Shell.dev && !!plugin && plugin.get("on", true)
    readonly property var schedule: !wanted ? null : Object.assign({
        "day": Number(plugin.get("day", 6600)),
        "night": Number(plugin.get("night", 3900))
    }, plugin.get("useLocation", false) ? {
        "location": [Number(plugin.get("lat", 55.75)), Number(plugin.get("lon", 37.62))]
    } : {
        "sunrise": String(plugin.get("sunrise", "07:00")),
        "sunset": String(plugin.get("sunset", "20:00"))
    })
    onScheduleChanged: ScreenTune.night = schedule
    Component.onCompleted: ScreenTune.night = schedule
    Component.onDestruction: ScreenTune.night = null
}
