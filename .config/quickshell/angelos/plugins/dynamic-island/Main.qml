pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Dynamic Island из строки текста песни: клик по строке на панели раскрывает
// остров (трек, текст, телефон), файл, притащенный на строку, улетает на
// телефон через KDE Connect. Панель и OSD не трогаем.
Item {
    id: root

    property var plugin
    readonly property alias phone: phone
    readonly property alias mirror: mirror

    property bool open: false
    // экран, где мышь над строкой на панели: окно острова готовится заранее
    property string warmScreen: ""
    function warm(screen, on) {
        if (on) {
            coolDown.stop();
            warmScreen = screen;
        } else if (warmScreen === screen)
            coolDown.restart();
    }
    Timer {
        id: coolDown
        interval: 1500
        onTriggered: root.warmScreen = ""
    }
    // строка на панели, когда нет ни текста, ни трека: остров всегда на месте
    readonly property string idleText: phone.ready ? phone.name + (phone.battery >= 0 ? " · " + phone.battery + "%" + (phone.charging ? " ⚡" : "") : "") : ""
    property bool dragMode: false        // открыт перетаскиванием файла: без «ловушки» кликов
    property string screenName: ""
    property var anchorItem: null

    function show(item, screen, drag) {
        anchorItem = item;
        screenName = screen;
        dragMode = drag;
        byJob = false;
        afterDrop.stop();
        open = true;
    }
    function close() {
        open = false;
    }
    function toggle(item, screen) {
        if (open && screenName === screen && !dragMode)
            close();
        else
            show(item, screen, false);
    }
    function dragEnter(item, screen) {
        if (!open)
            show(item, screen, true);
        dragHold.stop();
    }
    // файл увели с острова — подождать, вдруг вернётся
    function dragLeft() {
        if (dragMode && !afterDrop.running)
            dragHold.restart();
    }
    Timer {
        id: dragHold
        interval: 700
        onTriggered: if (root.dragMode && !root.byJob)
            root.close()
    }
    // что бросили: файлы с диска → как есть; картинка из браузера → скачать и
    // отправить файлом; просто ссылка или текст → текстом. where: bar | island
    signal droppedFrom(string where, real x, real y)
    function handleDrop(d, where, x, y) {
        const fmts = d.formats || [];
        const urls = (d.urls || []).map(u => String(u));
        const get = f => {
            try {
                return fmts.includes(f) ? String(d.getDataAsString(f) || "") : "";
            } catch (e) {
                return "";
            }
        };
        const html = d.hasHtml ? String(d.html || "") : get("text/html");
        // Pinterest и др. кладут свои данные только в пакет Firefox/Zen
        // (application/x-moz-custom-clipdata, строки UTF-16) — достаём из него ссылки
        let moz = "";
        if (fmts.includes("application/x-moz-custom-clipdata")) {
            try {
                const b = new Uint8Array(d.getDataAsArrayBuffer("application/x-moz-custom-clipdata"));
                let le = "", be = "";
                for (let i = 0; i + 1 < b.length; i += 2) {
                    le += String.fromCharCode(b[i] | b[i + 1] << 8);
                    be += String.fromCharCode(b[i] << 8 | b[i + 1]);
                }
                moz = (le.match(/https?:/g) || []).length >= (be.match(/https?:/g) || []).length ? le : be;
                moz = moz.replace(/[\u0000-\u001f]+/g, " ");
                console.log("[island] moz clipdata:", b.length, "bytes:", moz.slice(0, 1500));
            } catch (e) {
                console.log("[island] moz clipdata unreadable:", e);
            }
        }
        const mozUrls = (moz.match(/https?:\/\/[^\s"'<>\\]+/g) || []).map(u => u.replace(/&amp;/g, "&"));
        console.log("[island] drop formats:", JSON.stringify(fmts), "urls:", JSON.stringify(urls).slice(0, 300), "html:", html.slice(0, 300));
        if (!phone.ready)
            return false;

        const files = urls.filter(u => u.startsWith("file://"));
        let ok = false;
        if (files.length)
            ok = phone.sendFiles(files);
        else {
            const isFile = u => /\.(jpe?g|png|gif|webp|avif|bmp|mp4|webm|mov|mp3|ogg|pdf|zip)(\?|#|$)/i.test(u);
            const web = urls.find(u => /^https?:/i.test(u)) || (d.hasText && /^https?:\/\/\S+$/.test(String(d.text).trim()) ? String(d.text).trim() : "");
            // картинка: <img> из html, «обещание файла» Firefox/Zen, или сама ссылка, если это файл
            let img = "";
            const m = html.match(/<img[^>]*\ssrc=["']([^"']+)["']/i);
            if (m && /^https?:/i.test(m[1]))
                img = m[1].replace(/&amp;/g, "&");
            if (!img) {
                const promise = get("application/x-moz-file-promise-url").trim();
                if (/^https?:/i.test(promise))
                    img = promise;
            }
            if (!img && web && isFile(web))
                img = web;
            if (!img) {
                // из пакета Firefox: сначала картинка с CDN Pinterest, потом любая картинка
                img = mozUrls.find(u => /pinimg\.com/i.test(u) && isFile(u)) || mozUrls.find(u => isFile(u)) || "";
                const m2 = !img && moz.match(/<img[^>]*\ssrc=["']([^"']+)["']/i);
                if (m2 && /^https?:/i.test(m2[1]))
                    img = m2[1].replace(/&amp;/g, "&");
            }
            if (img)
                ok = phone.sendWebFile(img);
            else if (web)
                ok = phone.sendFiles([web]);
            else if (d.hasText && String(d.text).trim() !== "")
                ok = phone.sendText(String(d.text));
        }
        if (!ok && !files.length) {
            // ничего понятного не пришло — сказать об этом, а не молча закрыться
            phone.reject("Сайт не отдал картинку при перетаскивании");
            ok = true;
        }
        if (ok) {
            droppedFrom(where, x || 0, y || 0);
            dropped();
        }
        return ok;
    }
    // файл бросили: показать «отправляю / готово» и закрыться
    function dropped() {
        dragHold.stop();
        afterDrop.restart();
    }
    Timer {
        id: afterDrop
        interval: 2400
        onTriggered: {
            if (root.phone.state === "sending")
                restart();
            else if (root.dragMode)
                root.close();
        }
    }

    Component.onCompleted: Shell.lyricsHook = root
    Component.onDestruction: {
        if (Shell.lyricsHook === root)
            Shell.lyricsHook = null;
    }

    function anchorFor(screen) {
        const l = Shell.lyricsItems[screen];
        return l && l.visible ? l : null;
    }
    function focusedName() {
        return Shell.focusedScreen ? Shell.focusedScreen.name : "";
    }
    // остров открыла сама передача (не клик и не перетаскивание)
    property bool byJob: false

    Mirror {
        id: mirror
        name: phone.name !== "" ? phone.name : "Телефон"
        onLaunched: root.close()
    }

    PhoneLink {
        id: phone
        watching: root.open
        // KDE Connect отправляет что-то не через остров (Dolphin, «Отправить на…»)
        onExternalSend: {
            if (!root.open) {
                root.show(root.anchorFor(root.focusedName()), root.focusedName(), true);
                root.byJob = true;
            }
            root.dropped();
        }
        onOtherJobStarted: otherDelay.restart()
        onOtherJobChanged: if (!otherJob && root.byJob && root.open && phone.state === "idle")
            otherClose.restart()
        // после диалога выбора файла — показать полёт в маленьком острове
        onPicked: files => {
            root.show(root.anchorItem, root.screenName, true);
            phone.sendFiles(files);
            root.dropped();
        }
    }

    // долгая чужая задача (копирование в Dolphin и т. п.) — показать прогресс
    Timer {
        id: otherDelay
        interval: 900
        onTriggered: if (phone.otherJob && !root.open) {
            root.show(root.anchorFor(root.focusedName()), root.focusedName(), true);
            root.byJob = true;
        }
    }
    Timer {
        id: otherClose
        interval: 1200
        onTriggered: if (root.byJob && !phone.otherJob && phone.state === "idle")
            root.close()
    }

    // я в войсе Discord (шлёт Equicord-плагин AngelosFriends раз в 30 с): {channel, guild, since}
    property var voice: null
    property real voiceSeen: 0
    Timer {
        interval: 20000
        running: !!root.voice
        repeat: true
        // Discord закрыли или плагин замолчал — не показывать старое время
        onTriggered: if (Date.now() - root.voiceSeen > 95000)
            root.voice = null
    }

    IpcHandler {
        target: "island"
        // qs -c angelos ipc call island voice '{"channel":"…","since":<ms>}' | '{}'
        function voice(json: string): void {
            let v = null;
            try {
                v = JSON.parse(json);
            } catch (e) {}
            root.voiceSeen = Date.now();
            root.voice = v && v.since > 0 ? v : null;
        }
        // qs -c angelos ipc call island toggle — на экране в фокусе (можно повесить на клавишу)
        function toggle(): void {
            const s = Shell.focusedScreen ? Shell.focusedScreen.name : "";
            if (root.open)
                root.close();
            else
                root.show(null, s, false);
        }
        // экран телефона: включить / выключить трансляцию
        function mirror(): void {
            root.mirror.toggle();
        }
        // размер окна с телефоном: + | - | full
        function mirrorSize(how: string): void {
            if (how === "+")
                root.mirror.grow();
            else if (how === "-")
                root.mirror.shrink();
            else if (how === "full")
                root.mirror.toggleFull();
        }
        function mirrorState(): string {
            const m = root.mirror;
            return JSON.stringify({ state: m.state, running: m.running, audio: m.audio, winId: m.winId, ratio: m.ratio, winHeight: m.winHeight, full: m.full, tries: m.tries });
        }
        function mirrorAudio(): void {
            root.mirror.setAudio(!root.mirror.audio);
        }
        function mirrorFake(): void {
            root.mirror.startFake();
        }
        function dragTest(): void {
            root.show(null, Shell.focusedScreen ? Shell.focusedScreen.name : "", true);
        }
        function close(): void {
            root.close();
        }
        function send(path: string): void {
            root.show(null, Shell.focusedScreen ? Shell.focusedScreen.name : "", true);
            root.phone.sendFiles([path]);
            root.dropped();
        }
        // показать анимацию без настоящей отправки: done | error
        function fxTest(result: string): void {
            root.show(null, Shell.focusedScreen ? Shell.focusedScreen.name : "", true);
            root.phone.fake(result);
            root.dropped();
        }
    }

    Variants {
        model: Shell.screens
        IslandPopup {
            host: root
        }
    }
}
