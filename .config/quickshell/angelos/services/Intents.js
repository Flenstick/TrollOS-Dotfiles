.pragma library

// What a few typed words mean (services/Angel → "Ask…"). Local, no network, forgiving:
// every word is compared with the stems below by edit distance (a swapped pair of letters
// is one edit), so "вирни ангила" and "bring teh angel" still count; text typed in the
// wrong keyboard layout ("dthyb fyutkf") is read in the other one too.
//
// A stem ending in "*" matches the beginning of a word (вернуть, вернись, верните…), a
// bare stem the whole word. Stems of 5 letters and more allow one typo, of 8 and more
// two; shorter ones must be exact. `not` lists words that only look like a stem
// ("верно" is not "верни").
//
//   strong  one of these alone is the intent ("верни ангела", "отпусти")
//   weak    these mean it only when nothing else in the text does (Angel asks the
//           settings questions first): "назад", "домой", "please", "out"

const intents = {
    // the player wants out of hell: the angel back, heaven, the way out
    "plea": {
        "strong": ["верн*", "вертай*", "отпуст*", "отпущ*", "выпуст*", "выпущ*", "освобод*", "ангел*", "анегл*", "святош*", "умоля*", "наверх*", "небес*", "небо", "рай", "рая", "раю", "раем", "сбеж*", "побег*", "выбрат*", "выбер*", "выбир*", "спаси", "спасите", "помилуй*", "пощад*",
            "angel*", "heaven*", "return*", "release*", "escape*", "mercy", "spare"],
        "weak": ["выход*", "выйт*", "выйд*", "выпус*", "назад", "обратн*", "домой", "уйди", "уйдешь", "уходи", "уйти", "уберись", "прогон*", "прогна*", "свобод*", "пожалуйст*", "прошу", "хватит", "отстань",
            "back", "out", "home", "away", "leave", "free", "please", "save", "stop", "beg*"],
        "not": ["верно", "верный", "верная", "верное", "верные", "вернее", "вернейший", "вера", "веры", "верю", "веришь", "верить", "верит", "верх"]
    },
    // "What did I sign?" (D2): the pact, its terms, what the player agreed to — the one in
    // the corner shows the paper. Bare words where a stem would catch everyday ones
    // ("сделк*" would take "сделать", "sign*" — "sing"). The weak words are only the
    // question ("покажи", "what"): they break a tie with a plea, never count alone
    "signed": {
        "strong": ["подпис*", "подпиш*", "договор*", "контракт*", "соглас*", "услови*", "пакт*", "расписк*", "сделка", "сделку", "сделки", "сделке",
            "sign", "signed", "signing", "signature*", "contract*", "agree*", "terms", "pact*", "bargain*", "covenant*"],
        "weak": ["покаж*", "показ*", "что", "чо", "чего", "какие", "какой", "какая", "каком", "где", "прочит*", "прочти", "читать",
            "what", "whats", "show*", "which", "where", "read"],
        "not": ["подписка", "подписки", "подписку", "подпиской", "подписок", "подписке", "подписчик", "подписчики", "подписчиков", "подписаться", "подпишись", "подпишитесь"]
    }
};

// ---- text → words ----
const toRu = {
    "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г", "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ",
    "a": "ф", "s": "ы", "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д", ";": "ж", "'": "э",
    "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и", "n": "т", "m": "ь", ",": "б", ".": "ю", "`": "ё"
};
const toEn = (function () {
    const m = {};
    for (const k in toRu)
        m[toRu[k]] = k;
    return m;
})();
function swapLayout(s, map) {
    let out = "";
    for (const ch of s)
        out += map[ch] !== undefined ? map[ch] : ch;
    return out;
}
function words(s) {
    return String(s || "").toLowerCase().replace(/ё/g, "е")
    // "пожаааалуйста" → "пожалуйста"
    .replace(/(.)\1{2,}/g, "$1").split(/[^a-zа-я0-9]+/).filter(w => w.length > 0);
}
// the readings of a text: as typed, and in the other layout when it is all one script
function readings(text) {
    const raw = String(text || "").toLowerCase();
    const out = [words(raw)];
    if (/[a-z]/.test(raw) && !/[а-яё]/.test(raw))
        out.push(words(swapLayout(raw, toRu)));
    else if (/[а-яё]/.test(raw) && !/[a-z]/.test(raw))
        out.push(words(swapLayout(raw, toEn)));
    return out;
}

// ---- comparing ----
// optimal string alignment distance (Damerau–Levenshtein without repeated edits)
function distance(a, b, max) {
    if (Math.abs(a.length - b.length) > max)
        return max + 1;
    let prev2 = [], prev = [], cur = [];
    for (let j = 0; j <= b.length; j++)
        prev[j] = j;
    for (let i = 1; i <= a.length; i++) {
        cur = [i];
        let best = i;
        for (let j = 1; j <= b.length; j++) {
            const cost = a[i - 1] === b[j - 1] ? 0 : 1;
            let v = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
            if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1])
                v = Math.min(v, prev2[j - 2] + 1);
            cur[j] = v;
            best = Math.min(best, v);
        }
        if (best > max)
            return max + 1;
        prev2 = prev;
        prev = cur;
    }
    return prev[b.length];
}
function tolerance(n) {
    return n >= 8 ? 2 : n >= 5 ? 1 : 0;
}
// does the word fit the stem ("верн*" ↔ "вирните")
function fits(word, stem) {
    const prefix = stem.endsWith("*");
    const s = prefix ? stem.slice(0, -1) : stem;
    const tol = tolerance(s.length);
    if (!prefix)
        return word === s || (tol > 0 && distance(word, s, tol) <= tol);
    if (word.startsWith(s))
        return true;
    if (tol === 0) {
        // a 4-letter stem: one typo past the first letter ("вирни" → "верн*")
        return s.length === 4 && word.length >= 4 && word[0] === s[0] && distance(word.slice(0, 4), s, 1) <= 1;
    }
    // the word's own beginning, a letter shorter or longer (a dropped or doubled letter)
    for (const n of [s.length, s.length - 1, s.length + 1])
        if (n > 0 && n <= word.length && distance(word.slice(0, n), s, tol) <= tol)
            return true;
    return false;
}
function hits(list, ws, not) {
    let n = 0;
    for (const w of ws) {
        if (not.indexOf(w) >= 0)
            continue;
        if (list.some(stem => fits(w, stem)))
            n++;
    }
    return n;
}

// how strongly the text means the intent: {strong, weak} word counts, the best reading
function score(text, id) {
    const it = intents[id];
    if (!it)
        return {
            "strong": 0,
            "weak": 0
        };
    let best = {
        "strong": 0,
        "weak": 0
    };
    for (const ws of readings(text)) {
        const r = {
            "strong": hits(it.strong || [], ws, it.not || []),
            "weak": hits(it.weak || [], ws, it.not || [])
        };
        if (r.strong > best.strong || (r.strong === best.strong && r.weak > best.weak))
            best = r;
    }
    return best;
}
// is `a` what the text means rather than `b`: more of a's strong words, or as many and a
// question of a's ("покажи договор с ангелом" is about the pact, "отпусти, я не
// подписывал" and "верни ангела, я ничего не подписывал" are pleas)
function stronger(text, a, b) {
    const x = score(text, a), y = score(text, b);
    return x.strong > y.strong || (x.strong > 0 && x.strong === y.strong && x.weak > 0);
}
function strong(text, id) {
    return score(text, id).strong > 0;
}
function weak(text, id) {
    const s = score(text, id);
    return s.strong > 0 || s.weak > 0;
}
