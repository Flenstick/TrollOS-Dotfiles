/*
 * angelOS friends — когда друг из офлайна заходит в сеть, по панели angelOS
 * пробегает пиксельный человечек с его аватаркой и ником. Тир angelOS может
 * по нему выстрелить: если человек в войсе, его кикает из голосового канала.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { definePluginSettings } from "@api/Settings";
import { Logger } from "@utils/Logger";
import definePlugin, { OptionType, PluginNative } from "@utils/types";
import { ChannelStore, GuildMemberStore, GuildStore, PermissionsBits, PermissionStore, PresenceStore, RelationshipStore, RestAPI, SelectedChannelStore, UserStore, VoiceStateStore } from "@webpack/common";

const Native = VencordNative.pluginHelpers.AngelosFriends as PluginNative<typeof import("./native")>;
const logger = new Logger("AngelosFriends");

const settings = definePluginSettings({
    cooldownMinutes: {
        type: OptionType.NUMBER,
        description: "Не показывать одного и того же друга чаще, чем раз в N минут",
        default: 15
    },
    noCooldown: {
        type: OptionType.STRING,
        description: "ID через запятую, для кого кулдауна нет: пробегают каждый раз.",
        default: ""
    },
    ignoreIdle: {
        type: OptionType.BOOLEAN,
        description: "Не показывать, если друг зашёл сразу «неактивным»",
        default: false
    },
    kickOnShot: {
        type: OptionType.BOOLEAN,
        description: "Попал из тира по человеку в войсе — кикнуть его из голосового канала (нужно право «Перемещать участников»).",
        default: true
    },
    onlyMyChannel: {
        type: OptionType.BOOLEAN,
        description: "Кикать только из того канала, где сижу я сам.",
        default: false
    },
    voiceJoins: {
        type: OptionType.BOOLEAN,
        description: "Пускать человечка, когда кто-то заходит в мой голосовой канал.",
        default: true
    }
});

const last = new Map<string, string>();       // id → последний известный статус
const shownAt = new Map<string, number>();    // id → когда последний раз пробегал
let startedAt = 0;
let pollGen = 0;
let voiceSince = 0;                           // когда я зашёл в войс (для Dynamic Island)
let voiceBeat: ReturnType<typeof setInterval> | null = null;

function status(id: string) {
    return PresenceStore.getStatus(id) ?? "offline";
}

function snapshot() {
    for (const id of RelationshipStore.getFriendIDs())
        last.set(id, status(id));
}

const dbg = (line: string) => Native.log(line);
const noCooldown = (id: string) => settings.store.noCooldown.split(",").map(s => s.trim()).includes(id);

// голосовой канал человека, если его оттуда можно кикнуть
function kickableChannel(id: string) {
    const vs = VoiceStateStore.getVoiceStateForUser(id);
    const why = (r: string) => (dbg(`${id}: нельзя кикнуть — ${r}`), null);
    if (!vs?.channelId) return why("не в войсе");
    if (id === UserStore.getCurrentUser().id) return why("это я");
    if (settings.store.onlyMyChannel && vs.channelId !== SelectedChannelStore.getVoiceChannelId()) return why("не в моём канале");
    const channel = ChannelStore.getChannel(vs.channelId);
    if (!channel?.guild_id) return why("звонок не на сервере");
    if (!PermissionStore.can(PermissionsBits.MOVE_MEMBERS, channel)) return why(`нет права «Перемещать участников» в «${channel.name}»`);
    return channel;
}

function send(id: string, st: string) {
    const user = UserStore.getUser(id);
    if (!user) return;
    const vs = VoiceStateStore.getVoiceStateForUser(id);
    const channel = vs?.channelId ? ChannelStore.getChannel(vs.channelId) : null;
    const kickable = settings.store.kickOnShot && !!kickableChannel(id);
    Native.arrive(JSON.stringify({
        id,
        name: RelationshipStore.getNickname(id) || (channel?.guild_id && GuildMemberStore.getNick(channel.guild_id, id)) || user.globalName || user.username,
        avatar: user.getAvatarURL(undefined, 64, false),
        status: st,
        voice: channel?.name ?? "",
        kickable
    }));
}

function check(ids: string[]) {
    // первые секунды после запуска Discord присылает статусы пачкой — молчим
    const quiet = Date.now() - startedAt < 30_000;
    for (const id of ids) {
        if (!RelationshipStore.isFriend(id)) continue;
        const now = status(id);
        const before = last.get(id) ?? "offline";
        last.set(id, now);
        if (quiet || before !== "offline" || now === "offline") continue;
        if (now === "idle" && settings.store.ignoreIdle) continue;
        const prev = shownAt.get(id) ?? 0;
        if (!noCooldown(id) && Date.now() - prev < settings.store.cooldownMinutes * 60_000) continue;
        shownAt.set(id, Date.now());
        send(id, now);
    }
}

function kick(id: string) {
    if (!settings.store.kickOnShot) return dbg("кик выключен в настройках");
    const channel = kickableChannel(id);
    if (!channel) return;
    dbg(`${id}: кикаю из «${channel.name}»`);
    RestAPI.patch({ url: `/guilds/${channel.guild_id}/members/${id}`, body: { channel_id: null } })
        .then(() => dbg(`${id}: кикнут`))
        .catch(e => {
            logger.warn("Не получилось кикнуть", id, e);
            dbg(`${id}: Discord отказал — ${e?.status ?? ""} ${JSON.stringify(e?.body ?? e?.message ?? e)}`);
        });
}

function releaseVoice() {
    const ch = SelectedChannelStore.getVoiceChannelId();
    if (!ch) return dbg("voice: я не в войсе");
    const me = UserStore.getCurrentUser().id;
    const ids = Object.keys(VoiceStateStore.getVoiceStatesForChannel(ch)).filter(id => id !== me);
    dbg(`voice: в моём канале ещё ${ids.length}`);
    for (const id of ids) send(id, status(id) === "offline" ? "online" : status(id));
}

// остров angelOS тихо пишет, сколько я в войсе; раз в 30 с подтверждаем,
// чтобы после перезапуска оболочки или закрытия Discord он не врал
function reportVoice() {
    const ch = SelectedChannelStore.getVoiceChannelId();
    if (!ch) {
        if (voiceSince) Native.island("{}");
        voiceSince = 0;
        return;
    }
    if (!voiceSince) voiceSince = Date.now();
    const channel = ChannelStore.getChannel(ch);
    const guild = channel?.guild_id ? GuildStore.getGuild(channel.guild_id) : null;
    Native.island(JSON.stringify({ channel: channel?.name || "звонок", guild: guild?.name ?? "", since: voiceSince }));
}

async function poll() {
    const gen = ++pollGen;
    Native.listen();
    dbg("плагин запущен, жду команды");
    while (gen === pollGen) {
        const cmd = await Native.next();
        if (!cmd || gen !== pollGen) continue;
        const [what, arg] = cmd.split(" ");
        try {
            if (what === "shot" && /^\d{15,21}$/.test(arg)) kick(arg);
            else if (what === "voice") releaseVoice();
        } catch (e) {
            logger.error("Команда", cmd, e);
            dbg(`ошибка на «${cmd}»: ${e}`);
        }
    }
}

export default definePlugin({
    name: "AngelosFriends",
    description: "Друг зашёл в сеть — по панели angelOS пробегает его пиксельный человечек; выстрел из тира кикает из войса",
    authors: [{ name: "flen", id: 0n }],
    enabledByDefault: true,
    settings,

    start() {
        startedAt = Date.now();
        snapshot();
        poll();
        reportVoice();
        voiceBeat = setInterval(reportVoice, 30_000);
    },
    stop() {
        pollGen++;
        if (voiceBeat) clearInterval(voiceBeat);
        voiceBeat = null;
        if (voiceSince) Native.island("{}");
        voiceSince = 0;
        last.clear();
    },

    flux: {
        PRESENCE_UPDATES({ updates }: { updates: { user: { id: string; }; }[]; }) {
            const ids = [...new Set(updates.map(u => u.user?.id).filter(Boolean))];
            // сторы обновляются в том же диспатче — читаем статус чуть позже
            setTimeout(() => check(ids), 0);
        },
        VOICE_STATE_UPDATES({ voiceStates }: { voiceStates: { userId: string; channelId?: string | null; oldChannelId?: string | null; }[]; }) {
            const me = UserStore.getCurrentUser().id;
            if (voiceStates.some(vs => vs.userId === me)) setTimeout(reportVoice, 0);
            if (!settings.store.voiceJoins) return;
            const mine = SelectedChannelStore.getVoiceChannelId();
            for (const vs of voiceStates) {
                if (!mine || vs.channelId !== mine || vs.oldChannelId === mine || vs.userId === me) continue;
                if (!noCooldown(vs.userId) && Date.now() - (shownAt.get(vs.userId) ?? 0) < 10_000) continue;
                shownAt.set(vs.userId, Date.now());
                setTimeout(() => send(vs.userId, status(vs.userId) === "offline" ? "online" : status(vs.userId)), 0);
            }
        },
        CONNECTION_OPEN() {
            startedAt = Date.now();
            setTimeout(snapshot, 5000);
        }
    }
});
