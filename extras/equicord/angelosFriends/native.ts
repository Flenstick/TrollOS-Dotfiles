/*
 * angelOS friends — передаёт «друг зашёл в сеть» в оболочку angelOS (Quickshell)
 * и принимает от неё команды тира через unix-сокет $XDG_RUNTIME_DIR/angelos-friends.sock:
 *   shot <userId>  — по человечку попали (если он в войсе — кикнуть)
 *   voice          — выпустить по панели всех из моего голосового канала
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { execFile } from "child_process";
import { appendFileSync, rmSync } from "fs";
import { createServer, Server } from "net";
import { join } from "path";

// payload — JSON {id, name, avatar, status, voice, kickable}; начинается с «{», поэтому qs не примет его за флаг
export function arrive(_: unknown, payload: string) {
    execFile("qs", ["-c", "angelos", "ipc", "call", "friends", "arrive", payload], () => { });
}

// сколько я в войсе — в Dynamic Island: {channel, guild, since} или {} (вышел)
export function island(_: unknown, payload: string) {
    execFile("qs", ["-c", "angelos", "ipc", "call", "island", "voice", payload], () => { });
}

const SOCK = join(process.env.XDG_RUNTIME_DIR || "/tmp", "angelos-friends.sock");
const LOG = join(process.env.XDG_RUNTIME_DIR || "/tmp", "angelos-friends.log");

export function log(_: unknown, line: string) {
    appendFileSync(LOG, `${new Date().toLocaleTimeString("ru")} ${String(line).slice(0, 500)}\n`);
}
let server: Server | null = null;
const pending: string[] = [];
let waiter: ((cmd: string | null) => void) | null = null;

function push(cmd: string) {
    log(null, `<- ${cmd}${waiter ? "" : " (в очередь)"}`);
    if (waiter) {
        const w = waiter;
        waiter = null;
        w(cmd);
        return;
    }
    pending.push(cmd);
    if (pending.length > 50) pending.shift();
}

export function listen() {
    if (server) return;
    rmSync(SOCK, { force: true });
    server = createServer(c => {
        let buf = "";
        c.setEncoding("utf8");
        const drain = (all: boolean) => {
            const lines = buf.split("\n");
            buf = all ? "" : lines.pop() ?? "";
            for (const l of lines) if (l.trim()) push(l.trim());
        };
        c.on("data", d => { buf += d; drain(false); });
        c.on("end", () => drain(true));
        c.on("error", e => console.warn("AngelosFriends: клиент сокета", e.message));
    });
    server.on("error", e => console.error("AngelosFriends: сокет", e.message));
    server.listen(SOCK);
}

// рендерер ждёт следующую команду (long-poll); null — просто таймаут
export function next(_: unknown): Promise<string | null> {
    const queued = pending.shift();
    if (queued !== undefined) return Promise.resolve(queued);
    waiter?.(null);
    return new Promise(res => {
        waiter = res;
        setTimeout(() => {
            if (waiter !== res) return;
            waiter = null;
            res(null);
        }, 30_000);
    });
}
