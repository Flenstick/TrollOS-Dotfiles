pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How hell looks right now: its palette, the stone behind the bar, the rim of windows and
// widgets, the dark over the wallpaper — described as data in story/circles.json, one entry
// per circle ("base" is hell before any circle and what every circle starts from). The game
// (services/Story) sets `circle`; Theme.hell* follow `palette`, so plugins that draw hell
// themselves change with it.
Singleton {
    id: root

    property string circle: "base"
    property var looks: ({})
    // what the shell draws if story/circles.json is missing or broken
    readonly property var fallback: ({
            "name": {
                "ru": "Ад",
                "en": "Hell"
            },
            "palette": {
                "body": "#0b0809",
                "plate": "#0f0a0b",
                "face": "#16100f",
                "faceAlt": "#1f1716",
                "sunken": "#070505",
                "edge": "#040303",
                "hi": "#2c211f",
                "lo": "#060404",
                "rim": "#3b2a26",
                "text": "#d9cbbd",
                "textDim": "#9c8f85",
                "accent": "#e2703f",
                "blood": "#6b2420",
                "ember": "#e2703f",
                "flame": "#c99a5e",
                "gold": "#8a7444"
            },
            "bar": {
                "texture": "stone",
                "colors": [
                    "#0c0909",
                    "#110d0d",
                    "#1a1413",
                    "#33201b"
                ],
                "scale": 10,
                "crack": 0.35,
                "glow": 0.12,
                "seed": 3
            },
            "edge": {
                "kind": "scorch",
                "colors": [
                    "#040303",
                    "#3b2a26",
                    "#e2703f",
                    "#24130f"
                ]
            },
            // the dark laid over the wallpaper (shaders/hell_backdrop.frag)
            "backdrop": {
                "dim": 0.5,
                "desat": 0.35,
                "vignette": 0.6,
                "tint": "#0b0809"
            },
            // what her fist breaks in this circle (Config.y2k.breakage "circle"), one of them each punch
            "breakage": ["glass", "tv", "burn", "claws", "sigil"],
            // the word after a reading on hell's widgets: "CPU · жар" — the metric first, always
            "labels": {
                "cpu": {
                    "ru": "жар",
                    "en": "heat"
                },
                "gpu": {
                    "ru": "пекло",
                    "en": "inferno"
                },
                "ram": {
                    "ru": "души",
                    "en": "souls"
                },
                "vram": {
                    "ru": "котёл",
                    "en": "cauldron"
                }
            }
        })
    // a circle's entry over "base" over the fallback, objects merged key by key
    function merged(...parts) {
        const out = {};
        for (const p of parts) {
            if (!p || typeof p !== "object")
                continue;
            for (const k in p) {
                const v = p[k];
                out[k] = v && typeof v === "object" && !Array.isArray(v) && out[k] && typeof out[k] === "object" && !Array.isArray(out[k]) ? merged(out[k], v) : v;
            }
        }
        return out;
    }
    readonly property var look: merged(fallback, looks.base, circle !== "base" ? looks[circle] : null)
    readonly property var palette: look.palette
    readonly property var bar: look.bar
    readonly property var edge: look.edge
    readonly property var backdrop: look.backdrop
    // the circle itself: its number (0 for "base"), title, one line about it, the demon's voice
    readonly property int number: look.n || 0
    readonly property var title: look.name || ({})
    readonly property var where: look.where || ({})
    readonly property string voice: look.voice || ""
    readonly property string ambient: backdrop && backdrop.ambient ? backdrop.ambient : ""
    // What her fist can break (widgets/BreakageArt; the index is shaders/breakage.frag's kind),
    // the ones that keep moving once they've spread (services/Cracks runs a clock for them), and
    // this circle's own set (story/circles.json → breakage: Config.y2k.breakage "circle")
    readonly property var breakageKinds: ["glass", "tv", "burn", "claws", "sigil", "fog", "whirl", "ooze", "coin", "ripple", "spatter", "pitch", "frost"]
    readonly property var breakageLiving: ["tv", "burn", "claws", "sigil", "ooze", "ripple", "pitch"]
    readonly property var breakage: {
        const own = (look.breakage || []).filter(k => breakageKinds.includes(k));
        return own.length ? own : ["glass"];
    }
    // how hell dresses Settings and the right-click menu here (story/circles.json → dress;
    // Config.y2k.hellSettings / hellMenu "circle"): the grimoire and the pentagram before any circle
    readonly property var dressSettingsIds: ["registry", "letter", "bill", "ledger", "tablet", "tomb", "thorns", "playbill", "ice"]
    readonly property var dressMenuIds: ["queue", "whirl", "plate", "roulette", "ripples", "tombs", "blades", "masks", "shards"]
    readonly property string dressSettings: look.dress && dressSettingsIds.concat(["grimoire"]).includes(look.dress.settings) ? look.dress.settings : "grimoire"
    readonly property string dressMenu: look.dress && dressMenuIds.concat(["pentagram"]).includes(look.dress.menu) ? look.dress.menu : "pentagram"
    function dressName(id) {
        return ({
                "grimoire": I18n.t("Гримуар", "The grimoire"),
                "registry": I18n.t("Дело", "The case file"),
                "letter": I18n.t("Письмо", "The letter"),
                "bill": I18n.t("Меню заведения", "The bill of fare"),
                "ledger": I18n.t("Гроссбух", "The ledger"),
                "tablet": I18n.t("Скрижаль", "The tablet"),
                "tomb": I18n.t("Гробница", "The tomb"),
                "thorns": I18n.t("Терновник", "The thorns"),
                "playbill": I18n.t("Афиша", "The playbill"),
                "ice": I18n.t("Лёд", "The ice")
            })[id] || I18n.t("Настройки", "Settings");
    }
    // what Settings wear in hell by the player's pick: "" (the usual window), grimoire or a circle's look
    readonly property string settingsPick: {
        const p = Config.y2k.hellSettings || "";
        return p === "circle" ? dressSettings : p === "grimoire" || dressSettingsIds.includes(p) ? p : "";
    }
    // "CPU · жар": the circle's word for a reading, after its plain name
    function label(id, plain) {
        const w = look.labels ? look.labels[id] : null;
        return w ? plain + " · " + I18n.label(w) : plain;
    }

    // the rare thing seen from the corner of an eye (services/HellAmbient drives it): 0 → 1 → 0
    // over a few seconds, on the windows whose seed matches `eventTarget` — one at a time
    property real event: 0
    property int eventTarget: -1             // a window's seed % 6; -2: the ground (the wallpaper's ambient)
    property real phase: 0                   // 0 → 1 through the event (the ambient moves with it)
    readonly property var ids: Object.keys(looks).filter(k => k !== "_comment")

    // The hell bar's colour roles (BarContent, PxButton.barInk, shaders/hell_bar_tint.frag),
    // each a key a circle's palette may set, else made from its other colours:
    //   barIcon    the icons — the text colour with a fifth of the accent: each circle's bar
    //              has its own hue at rest, far from the full accent of a state
    //   barHover   the plate under a widget the pointer is on — the plate a step lighter
    //   barActive  the plate under an open or switched-on widget — the plate toward the accent
    //   sprite     the body of a sprite or an app icon's darks — the first mix of the plate and
    //              the dim text that stands out from the plate (3:1), so a dark puppy shows
    //   spriteHi   a sprite's lighter parts (heads, highlights) — between sprite and text
    // The accent marks a state only: an open popup, a switch that is on, the active desk.
    function barRoles(pal) {
        const mixHex = (a, b, k) => {
            const x = Qt.color(a), y = Qt.color(b);
            const ch = v => ("0" + Math.round(v * 255).toString(16)).slice(-2);
            return "#" + ch(x.r + (y.r - x.r) * k) + ch(x.g + (y.g - x.g) * k) + ch(x.b + (y.b - x.b) * k);
        };
        let sprite = pal.sprite;
        if (!sprite)
            for (let k = 0.3; k <= 1.001; k += 0.05) {
                sprite = mixHex(pal.plate, pal.textDim, k);
                if (contrast(sprite, pal.plate) >= 3)
                    break;
            }
        return {
            "barIcon": pal.barIcon || mixHex(pal.text, pal.accent, 0.2),
            "barHover": pal.barHover || mixHex(pal.plate, pal.text, 0.1),
            "barActive": pal.barActive || mixHex(pal.plate, pal.accent, 0.2),
            "sprite": sprite,
            "spriteHi": pal.spriteHi || mixHex(sprite, pal.text, 0.45)
        };
    }
    readonly property var barRole: barRoles(palette)

    // WCAG contrast of two "#rrggbb" colours (tests check every circle's text roles)
    function contrast(a, b) {
        const lum = h => {
            const c = Qt.color(h);
            const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
            return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
        };
        const x = lum(a), y = lum(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    FileView {
        path: Quickshell.shellDir + "/story/circles.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.looks = JSON.parse(text());
            } catch (e) {
                console.warn("story/circles.json: " + e);
            }
        }
    }
}
