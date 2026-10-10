pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Where the windows of an output's active workspace are, in output coordinates.
// niri gives positions only for floating windows; with center-focused-column
// "always" the focused column sits in the middle of the working area and the
// others follow by width + gaps (same as angelos-shot / the Geiger counter).
// Used by the Windows 11 copy: Alt+Tab pictures and edge resizing.
Singleton {
    id: root

    property real gaps: 16
    property bool centred: true
    FileView {
        path: Quickshell.env("HOME") + "/.config/niri/cfg/layout.kdl"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const src = text().replace(/\/\/[^\n]*/g, "");
            const m = src.match(/\bgaps\s+([\d.]+)/);
            if (m)
                root.gaps = parseFloat(m[1]);
            root.centred = /center-focused-column\s+"always"/.test(src);
        }
    }
    function ts(w) {
        return w.focus_timestamp ? w.focus_timestamp.secs + w.focus_timestamp.nanos / 1e9 : 0;
    }
    // window id -> Qt.rect on the output (logical px). wholeOnly: only windows fully on screen
    function rectsOn(scr, wholeOnly) {
        const out = {};
        if (!scr || Niri.overviewOpen)
            return out;
        const ws = Niri.activeWorkspace(scr.name);
        if (!ws)
            return out;
        const ow = scr.width, oh = scr.height;
        const wa = root.workArea(scr);
        const mine = Niri.windows.filter(w => w.workspace_id === ws.id);
        const cols = {};
        for (const w of mine) {
            const lay = w.layout || {};
            if (w.is_floating && lay.tile_pos_in_workspace_view) {
                const off = lay.window_offset_in_tile || [0, 0];
                out[w.id] = Qt.rect(wa[0] + lay.tile_pos_in_workspace_view[0] + off[0], wa[1] + lay.tile_pos_in_workspace_view[1] + off[1], lay.window_size[0], lay.window_size[1]);
            } else if (!w.is_floating && lay.pos_in_scrolling_layout) {
                const c = lay.pos_in_scrolling_layout[0];
                (cols[c] = cols[c] || []).push(w);
            }
        }
        const order = Object.keys(cols).map(Number).sort((a, b) => a - b);
        if (!root.centred || !order.length)
            return out;
        let active = mine.find(w => w.id === ws.active_window_id && !w.is_floating && w.layout && w.layout.pos_in_scrolling_layout);
        if (!active)
            active = [].concat(...order.map(c => cols[c])).reduce((a, b) => ts(b) > ts(a) ? b : a);
        const acol = active.layout.pos_in_scrolling_layout[0];
        const width = {};
        for (const c of order)
            width[c] = Math.max(...cols[c].map(w => w.layout.tile_size[0]));
        const xs = {};
        xs[acol] = width[acol] >= ow - 0.5 ? 0 : wa[0] + (wa[2] - width[acol]) / 2;
        const i = order.indexOf(acol);
        for (let j = i + 1; j < order.length; j++)
            xs[order[j]] = xs[order[j - 1]] + width[order[j - 1]] + root.gaps;
        for (let j = i - 1; j >= 0; j--)
            xs[order[j]] = xs[order[j + 1]] - root.gaps - width[order[j]];
        for (const c of order) {
            const items = cols[c].slice().sort((a, b) => a.layout.pos_in_scrolling_layout[1] - b.layout.pos_in_scrolling_layout[1]);
            const heights = items.map(w => w.layout.tile_size[1]);
            const stacked = items.length > 1 && heights.reduce((a, b) => a + b, 0) + root.gaps * (items.length + 1) <= wa[3] + 1;
            let y = wa[1] + root.gaps;
            items.forEach((w, k) => {
                const lay = w.layout, th = heights[k];
                let ty;
                if (th >= oh - 0.5)
                    ty = 0;
                else if (stacked) {
                    ty = y;
                    y += th + root.gaps;
                } else
                    ty = wa[1] + Math.max(0, (wa[3] - th) / 2);
                const off = lay.window_offset_in_tile || [0, 0];
                const x0 = xs[c] + (width[c] - lay.tile_size[0]) / 2 + off[0];
                const y0 = ty + off[1];
                const whole = x0 >= -1 && y0 >= -1 && x0 + lay.window_size[0] <= ow + 1 && y0 + lay.window_size[1] <= oh + 1;
                if (whole || !wholeOnly)
                    out[w.id] = Qt.rect(x0, y0, lay.window_size[0], lay.window_size[1]);
            });
        }
        return out;
    }


    // the working area: the Windows taskbar keeps 48 px at the bottom
    function workArea(scr) {
        return [0, 0, scr.width, scr.height - (Config.bar.style === "windows" ? 48 : 0)];
    }
}
