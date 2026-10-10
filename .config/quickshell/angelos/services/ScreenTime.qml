pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

// TrollOS screen time, like GNOME's Wellbeing: how long you sit at the computer
// and in which apps — kept for months and years (Settings → Экранное время).
//
//   counting   while you're there: some input in the last 2 minutes (a playing
//              video keeps it, like the screensaver), not locked, no screensaver.
//              A tick every 15 s; a gap (sleep) never counts. Per day: the total,
//              per hour and per app (the focused window's app id)
//   the file   ~/.local/state/angelos/screen-time.json, the same shape as
//              angelOS's Wellbeing: {"version": 1, "days": {"2026-10-10":
//              {"s", "h": [24], "apps": {app_id: s}}}}. Nothing is dropped; days
//              older than 90 lose only the per-hour split (the totals stay)
Singleton {
    id: root

    readonly property var cfg: Config.screenTime
    readonly property bool ready: Config.ready && loaded
    property bool loaded: false
    property var days: ({})
    property int rev: 0                      // bumps on every counted tick (the page's charts follow it)

    readonly property bool here: !away.isIdle && !Shell.locked && !Idle.active
    readonly property bool counting: ready && cfg.track && here

    // ---- reading ----
    function dayKey(d) {
        return Qt.formatDate(d || new Date(), "yyyy-MM-dd");
    }
    function day(key) {
        rev;
        return days[key || dayKey()] || null;
    }
    readonly property int todaySeconds: {
        rev;
        const d = days[dayKey()];
        return d ? d.s || 0 : 0;
    }
    // seconds per hour of one day: [24]
    function hours(key) {
        const d = day(key);
        const h = d && d.h ? d.h : [];
        const out = [];
        for (let i = 0; i < 24; i++)
            out.push(h[i] || 0);
        return out;
    }
    // the days from `from` to `to` (Date, inclusive), oldest first: [{key, date, s}]
    function range(from, to) {
        rev;
        const out = [];
        const d = new Date(from.getFullYear(), from.getMonth(), from.getDate());
        while (d <= to) {
            const k = dayKey(d);
            out.push({
                "key": k,
                "date": new Date(d),
                "s": days[k] ? days[k].s || 0 : 0
            });
            d.setDate(d.getDate() + 1);
        }
        return out;
    }
    // the twelve months of a year: [{month, s}]
    function months(year) {
        rev;
        const out = [];
        for (let m = 0; m < 12; m++)
            out.push({
                "month": m,
                "s": 0
            });
        const p = String(year) + "-";
        for (const k of Object.keys(days))
            if (k.startsWith(p))
                out[parseInt(k.slice(5, 7)) - 1].s += days[k].s || 0;
        return out;
    }
    // [{id, name, s}] the most used apps over a list of day keys
    function topApps(keys, n) {
        rev;
        const sum = {};
        for (const k of keys) {
            const d = days[k];
            if (!d || !d.apps)
                continue;
            for (const id of Object.keys(d.apps))
                sum[id] = (sum[id] || 0) + d.apps[id];
        }
        return Object.keys(sum).map(id => ({
                    "id": id,
                    "name": appName(id),
                    "s": sum[id]
                })).sort((a, b) => b.s - a.s).slice(0, n || 8);
    }
    // the first day anything was counted ("" when nothing yet)
    readonly property string firstDay: {
        rev;
        const k = Object.keys(days).sort();
        return k.length ? k[0] : "";
    }
    function appName(id) {
        if (id === "quickshell" || id === "org.quickshell")
            return "TrollOS";
        const e = DesktopEntries.heuristicLookup(id);
        return e && e.name ? e.name : String(id).replace(/^.*\./, "");
    }
    function appIcon(id) {
        const e = DesktopEntries.heuristicLookup(id);
        return e && e.icon ? Quickshell.iconPath(e.icon, true) : "";
    }
    // 3725 → "1 ч 2 мин"; under a minute → "0 мин"
    function fmt(s) {
        const m = Math.floor((s || 0) / 60), h = Math.floor(m / 60), r = m % 60;
        if (!h)
            return I18n.t(r + " мин", r + " min");
        return r ? I18n.t(h + " ч " + r + " мин", h + " h " + r + " min") : I18n.t(h + " ч", h + " h");
    }

    // ---- counting ----
    IdleMonitor {
        id: away
        enabled: root.ready
        timeout: 120
        respectInhibitors: true
    }
    property double _last: Date.now()
    property int _ticks: 0
    property bool _dirty: false
    Timer {
        interval: 15000
        repeat: true
        running: root.ready
        onTriggered: root.tick()
    }
    function tick() {
        const t = Date.now();
        const dt = (t - _last) / 1000;
        _last = t;
        // a gap (sleep, a frozen shell) is not time at the computer
        if (dt <= 0 || dt > 45)
            return;
        if (counting)
            add(dt);
        if (++_ticks % 4 === 0 && _dirty)
            save();
    }
    function add(dt) {
        const k = dayKey();
        const d = days[k] || {
            "s": 0,
            "h": []
        };
        d.s = (d.s || 0) + dt;
        const h = d.h || [];
        const hr = new Date().getHours();
        for (let i = h.length; i <= hr; i++)
            h.push(0);
        h[hr] += dt;
        d.h = h;
        if (cfg.apps) {
            const w = Niri.focusedWindow;
            const id = String(w && w.app_id || "");
            if (id) {
                d.apps = d.apps || {};
                d.apps[id] = (d.apps[id] || 0) + dt;
            }
        }
        days[k] = d;
        _dirty = true;
        rev++;
    }

    // ---- the file ----
    readonly property string path: Config.stateDir + "/screen-time.json"
    FileView {
        id: file
        path: root.path
        printErrors: false
        onLoaded: {
            try {
                root.days = JSON.parse(text()).days || {};
            } catch (e) {
                root.days = {};
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
    function save() {
        if (!loaded)
            return;
        const old = dayKey(new Date(Date.now() - 90 * 86400000));
        const out = {};
        for (const k of Object.keys(days).sort()) {
            const d = days[k];
            const r = {
                "s": Math.round(d.s || 0)
            };
            if (k >= old && d.h)
                r.h = d.h.map(x => Math.round(x));
            if (d.apps) {
                // the 30 most used of the day; the rest is noise
                r.apps = {};
                for (const id of Object.keys(d.apps).sort((a, b) => d.apps[b] - d.apps[a]).slice(0, 30))
                    r.apps[id] = Math.round(d.apps[id]);
            }
            out[k] = r;
        }
        file.setText(JSON.stringify({
            "version": 1,
            "days": out
        }));
        _dirty = false;
    }
    // Settings → «Стереть историю»
    function clear() {
        days = {};
        rev++;
        save();
    }
    Component.onDestruction: if (_dirty)
        save()

    // `angelos screentime`
    function status() {
        return JSON.stringify({
            "today": fmt(todaySeconds),
            "todaySeconds": Math.round(todaySeconds),
            "here": here,
            "counting": counting,
            "apps": topApps([dayKey()], 5).map(a => a.name + " " + fmt(a.s))
        });
    }
}
