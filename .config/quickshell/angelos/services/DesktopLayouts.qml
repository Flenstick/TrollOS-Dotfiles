pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Whole-desktop layouts like Zorin's: one click sets the bar style, what sits
// where on it, the Start menu and the dock. "default" is the user's own setup,
// saved the moment another layout is picked and put back when it is picked again.
Singleton {
    id: root

    readonly property var right: ["media", "tray", "layout", "volume", "bell", "clock"]

    // the user's setup on 2026-10-10, used when nothing was saved yet
    readonly property var fallback: ({
            "bar": {
                "style": "taskbar",
                "floating": false,
                "layout": ({}),
                "hidden": [],
                "startStyle": "win11",
                "startAlign": "left",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": false
            }
        })

    // preview: bar top|bottom|none, float, dock bottom|left|none, menu grid|list|full|none + where, tasks left|center|none
    readonly property var presets: [
        {
            "id": "default",
            "label": I18n.t("Как сейчас", "Current"),
            "hint": I18n.t("твоя раскладка — к ней можно вернуться", "Your own layout, always one click away"),
            "preview": {
                "bar": "bottom",
                "tasks": "left",
                "menu": "grid",
                "menuAt": "left"
            }
        },
        {
            "id": "macos",
            "label": "macOS",
            "hint": I18n.t("полоса сверху, док снизу, приложения на весь экран", "Top strip, a dock below, full screen apps"),
            "preview": {
                "bar": "top",
                "dock": "bottom",
                "menu": "none"
            },
            "bar": {
                "style": "top",
                "floating": false,
                "layout": {
                    "left": ["start", "workspaces"],
                    "center": ["lyrics"],
                    "right": root.right
                },
                "hidden": ["tasks"],
                "startStyle": "fullscreen",
                "startAlign": "auto",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": true,
                "position": "bottom",
                "magnify": true
            }
        },
        {
            "id": "win11",
            "label": "Windows 11",
            "hint": I18n.t("«Пуск» и окна по центру панели", "Start and windows in the middle"),
            "preview": {
                "bar": "bottom",
                "tasks": "center",
                "menu": "grid",
                "menuAt": "center"
            },
            "bar": {
                "style": "taskbar",
                "floating": false,
                "layout": {
                    "left": ["workspaces", "lyrics"],
                    "center": ["start", "tasks"],
                    "right": root.right
                },
                "hidden": [],
                "startStyle": "win11",
                "startAlign": "center",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": false
            }
        },
        {
            "id": "windows",
            "label": I18n.t("Windows 11 — копия", "Windows 11 replica"),
            "hint": I18n.t("акрил, анимации Fluent, «Пуск» и флайауты как в Windows", "Acrylic, Fluent motion, Start and flyouts like on Windows"),
            "preview": {
                "bar": "bottom",
                "tasks": "center",
                "menu": "grid",
                "menuAt": "center",
                "win": true
            },
            "bar": {
                "style": "windows",
                "startStyle": "windows",
                "floating": false
            },
            "dock": {
                "enabled": false
            }
        },
        {
            "id": "compact",
            "label": I18n.t("Компактная панель", "Compact panel"),
            "hint": I18n.t("плавающая панель с отступами", "A floating panel with gaps around it"),
            "preview": {
                "bar": "bottom",
                "float": true,
                "tasks": "left",
                "menu": "grid",
                "menuAt": "left"
            },
            "bar": {
                "style": "taskbar",
                "floating": true,
                "layout": {
                    "left": ["start", "tasks"],
                    "center": ["lyrics"],
                    "right": ["workspaces", "tray", "layout", "volume", "bell", "clock"]
                },
                "hidden": ["media"],
                "startStyle": "win11",
                "startAlign": "left",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": false
            }
        },
        {
            "id": "ubuntu",
            "label": "Ubuntu",
            "hint": I18n.t("часы сверху по центру, док слева", "Clock on top, a dock on the left"),
            "preview": {
                "bar": "top",
                "dock": "left",
                "menu": "none",
                "clock": "center"
            },
            "bar": {
                "style": "top",
                "floating": false,
                "layout": {
                    "left": ["start", "workspaces", "lyrics"],
                    "center": ["clock"],
                    "right": ["media", "tray", "layout", "volume", "bell"]
                },
                "hidden": ["tasks"],
                "startStyle": "fullscreen",
                "startAlign": "auto",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": true,
                "position": "left",
                "magnify": false
            }
        },
        {
            "id": "classic",
            "label": "Windows Classic",
            "hint": I18n.t("кнопки окон с названиями, меню-список", "Window buttons with titles, a list menu"),
            "preview": {
                "bar": "bottom",
                "tasks": "labels",
                "menu": "list",
                "menuAt": "left"
            },
            "bar": {
                "style": "taskbar",
                "floating": false,
                "layout": {
                    "left": ["start", "tasks"],
                    "center": [],
                    "right": ["lyrics", "workspaces", "tray", "layout", "volume", "bell", "clock"]
                },
                "hidden": ["media"],
                "startStyle": "classic",
                "startAlign": "auto",
                "taskLabels": true,
                "showWindows": true
            },
            "dock": {
                "enabled": false
            }
        },
        {
            "id": "chromeos",
            "label": "ChromeOS",
            "hint": I18n.t("лаунчер слева, окна по центру", "Launcher on the left, windows centred"),
            "preview": {
                "bar": "bottom",
                "tasks": "center",
                "menu": "grid",
                "menuAt": "left"
            },
            "bar": {
                "style": "taskbar",
                "floating": false,
                "layout": {
                    "left": ["start", "lyrics"],
                    "center": ["tasks"],
                    "right": ["workspaces", "media", "tray", "layout", "volume", "bell", "clock"]
                },
                "hidden": [],
                "startStyle": "win11",
                "startAlign": "left",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": false
            }
        },
        {
            "id": "elementary",
            "label": "elementary OS",
            "hint": I18n.t("меню и часы сверху, ровный док снизу", "Menu and clock on top, a plain dock below"),
            "preview": {
                "bar": "top",
                "dock": "bottom",
                "menu": "grid",
                "menuAt": "topleft",
                "clock": "center"
            },
            "bar": {
                "style": "top",
                "floating": false,
                "layout": {
                    "left": ["start", "workspaces"],
                    "center": ["clock"],
                    "right": ["lyrics", "media", "tray", "layout", "volume", "bell"]
                },
                "hidden": ["tasks"],
                "startStyle": "win11",
                "startAlign": "left",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": true,
                "position": "bottom",
                "magnify": false
            }
        },
        {
            "id": "cinnamon",
            "label": "Cinnamon",
            "hint": I18n.t("меню-список, значки окон, столы справа", "List menu, window icons, desks on the right"),
            "preview": {
                "bar": "bottom",
                "tasks": "left",
                "menu": "list",
                "menuAt": "left"
            },
            "bar": {
                "style": "taskbar",
                "floating": false,
                "layout": {
                    "left": ["start", "tasks"],
                    "center": ["lyrics"],
                    "right": ["media", "workspaces", "tray", "layout", "volume", "bell", "clock"]
                },
                "hidden": [],
                "startStyle": "classic",
                "startAlign": "auto",
                "taskLabels": false,
                "showWindows": true
            },
            "dock": {
                "enabled": false
            }
        }
    ]

    readonly property string current: Config.bar.layoutPreset || "default"
    readonly property var ids: presets.map(p => p.id)
    function byId(id) {
        return presets.find(p => p.id === id) || null;
    }

    function snapshot() {
        const b = Config.bar, d = Config.dock;
        return {
            "bar": {
                "style": b.style,
                "floating": b.floating,
                "layout": JSON.parse(JSON.stringify(b.layout || {})),
                "hidden": (b.hidden || []).slice(),
                "startStyle": b.startStyle,
                "startAlign": b.startAlign,
                "taskLabels": b.taskLabels,
                "showWindows": b.showWindows
            },
            "dock": {
                "enabled": d.enabled,
                "position": d.position,
                "magnify": d.magnify
            }
        };
    }
    function put(values) {
        const b = values.bar || {}, d = values.dock || {};
        for (const k in b)
            Config.bar[k] = JSON.parse(JSON.stringify(b[k]));
        for (const k in d)
            Config.dock[k] = d[k];
    }

    function apply(id) {
        const p = byId(id);
        if (!p)
            return false;
        if (id === current && id !== "default")
            return true;
        // leaving the user's own layout: remember it first
        if (current === "default")
            Config.bar.layoutSaved = snapshot();
        Shell.closeStart();
        if (id === "default") {
            const saved = Config.bar.layoutSaved || {};
            put(saved.bar ? saved : fallback);
        } else {
            put(p);
            if (p.dock && p.dock.enabled && !(Config.dock.pinned || []).length)
                Config.dock.pinned = StartApps.frequent.slice(0, 7).map(a => a.id);
        }
        Config.bar.layoutPreset = id;
        return true;
    }
}
