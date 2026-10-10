.pragma library

// angelOS logos (widgets/AngelLogo.qml; Settings → Bar → Logo). ASCII bitmaps in the
// Icons.js alphabet ('#' ink, 'o' accent, 'x' accent2, 'y' gold, 'w' white, 'f' lavender,
// 'r' red) plus a few colours of their own that AngelLogo passes as a palette.

// ---- emblems: 19 wide; the first `halo` rows are the halo (horns while the demon rules) ----
const emblems = {
    // TrollOS: the red paint splat (no halo, so no horns either)
    splat: {
        halo: 0,
        rows: [
            ".rr..........",
            ".rrr....r..rr",
            "..rr......rrr",
            "...rr..r.rr..",
            ".r..rrrrrr...",
            "..rrrrrrrr.r.",
            "rr.rrrrrrrrr.",
            "rrrrrrrrrrr..",
            "...rrrrrrrr..",
            "..rrrrrrrrrrr",
            "..r..rrr.r.rr",
            ".....r...r...",
            "....rr......."
        ]
    },
    heart: {
        halo: 4,
        rows: [
            "......yyyyyyy......",
            ".....y.......y.....",
            "......yyyyyyy......",
            "...................",
            "#.....##...##.....#",
            "#w#..#wo#.#oo#..#w#",
            "#ww###ooo#ooo###ww#",
            ".#www#ooooooo#www#.",
            "..#w#.#ooooo#.#w#..",
            "...##..#ooo#..##...",
            "........#o#........",
            ".........#........."
        ]
    },
    pill: {
        halo: 4,
        rows: [
            "......yyyyyyy......",
            ".....y.......y.....",
            "......yyyyyyy......",
            "...................",
            "....###########....",
            "...#wwooo#xxxxx#...",
            "..#wooooo#xxxxxx#..",
            "..#oooooo#xxxxxw#..",
            "..#oooooo#xxxxxx#..",
            "...#ooooo#xxxxx#...",
            "....###########....",
            "..................."
        ]
    },
    // no halo: the demon turns the star red instead
    star: {
        halo: 0,
        rows: [
            "...x.....#.........",
            "..xwx...#w#........",
            "...x....#y#........",
            ".......#yyy#.......",
            ".....##yyyyy##.....",
            "....#yyyywyyyy#....",
            ".....##yyyyy##.....",
            ".......#yyy#.......",
            "........#y#.....x..",
            "........#y#....xwx.",
            ".........#.......x."
        ]
    },
    cd: {
        halo: 3,
        rows: [
            "......yyyyyyy......",
            ".....y.......y.....",
            "......yyyyyyy......",
            "......#######......",
            ".....#wwxxxoo#.....",
            "....#wxxyyyooo#....",
            "....#xxy###yoo#....",
            "....#xy##.##yo#....",
            "....#xxy###yox#....",
            "....#oxxyyyxxo#....",
            ".....#ooxxxxo#.....",
            "......#######......"
        ]
    },
    // a white kitty face: pink ears, a heart nose, blush ('p')
    kitty: {
        halo: 3,
        rows: [
            "......yyyyyyy......",
            ".....y.......y.....",
            "......yyyyyyy......",
            "..#.............#..",
            "..##...........##..",
            "..#o#.........#o#..",
            "..#oo#########oo#..",
            "..#wwwwwwwwwwwww#..",
            "..#www#wwwww#www#..",
            "..#wpwwwowowwwpw#..",
            "...#wwwwwowwwww#...",
            "....###########...."
        ]
    }
};
const horns = [
    "...r...........r...",
    "...rr.........rr...",
    "....rr.......rr....",
    ".....rr.....rr....."
];

// emblem rows: the halo swapped for horns while the demon rules
function emblem(name, demon) {
    const e = emblems[name] || emblems.heart;
    if (!demon || !e.halo)
        return e.rows;
    return horns.slice(horns.length - e.halo).concat(e.rows.slice(e.halo));
}
function emblemHasHalo(name) {
    return !!(emblems[name] || emblems.heart).halo;
}

// ---- pixel wordmarks (the text ones — classic, angel — are drawn by AngelLogo) ----
// Made by scripts/wordmark-art.py from pixel fonts, on the 9 px title font's grid, so
// their letters are as tall as "angel" set in it; `scale` is the art pixel against that
// grid (hell: Jacquard 24 at half of it).
//   windose: white sticker letters, an ink outline, a coloured rim; the O is a pill
//   hell:    Jacquard 24 blackletter in red, a dark-red shadow, drips ('r' 'd' 'k' 'e')
//   chrome:  Y2K bands white → silver → grey horizon → pink ('s' 'g' 'p'), a sparkle
const wordmarks = {
    windose: {
        scale: 1,
        rows: [
            "................................................",
            "................................................",
            "............................xxxxxxxxxxxxxxxxxxx.",
            "............................x##########x######xx",
            ".xxxxxxxxxxxxxxxxxxxxxxxxxxxx#ww##oooo###wwww##x",
            "xx#############x##############ww#owoooo#ww##ww#x",
            "x##wwwww#wwwww###wwwww##wwww##ww#oooooo#ww#####x",
            "x#ww##ww#ww##ww#ww##ww#ww##ww#ww#########wwww##x",
            "x#ww##ww#ww##ww#ww##ww#wwwwww#ww#wwwwww#####ww#x",
            "x#ww##ww#ww##ww#ww##ww#ww#####ww#wwwwww#ww##ww#x",
            "x##wwwww#ww##ww##wwwww##wwwww#ww##wwww###wwww##x",
            "xx##################ww#################x######xx",
            ".xxxxxxxxxxxxxxx#wwwww#xxxxxxxxxxxxxxxxxxxxxxxx.",
            "...............x#######x........................",
            "...............xxxxxxxxx........................"
        ]
    },
    hell: {
        scale: 0.5,
        rows: [
            "............................................................................",
            "............................................................................",
            "............................................................................",
            "............................................................................",
            "............................................................................",
            "............................................................................",
            "...........................................kkk.kkkkkkk..kkkk....kkkkkk.kkk..",
            "..........................................kkekkkeeekekk.keekk.kkkeeeekkkekk.",
            "..........................................kerdkerrrerdkkkrrekkkeerrrreeerdk.",
            "..........................................krrdkrdrrrddeeerrrekkrrddrrrrrddk.",
            "..........................................krrdkkdkdrderdddrrrdkrrdkkdrrddkk.",
            "....kkkkkkk..kkk.kkkk....kkkkk.....kkkkk..krrdkkkkkrdrrdkkrrrdkrreekkkddkk..",
            "....keeeeekkkkekkkeekk..kkeeekk...kkeeekk.krrdk.keerdrrdkkrrrdkrrrrekkkkk...",
            "...kkrddrrekkereeerrekkkkekrrekk.kkerrrdk.krrdk.kkdrdrrdkkrrrdkrdddreekkk...",
            "...kerdkrrddkkrrddrrddkkerdkrrekkkerddrekkkrrdk.keerdrrdkkrrrdkkekkkdreekk..",
            "...krrdkrrdkkkrrdkrrdkkkrrdkrrddkkrrdkkrdkkrrdk.kkdrdrrdkkrrrdkkkeeekkrrekk.",
            "...krrdkrrdk.krrdkrrdk.krrdkrrdkkkrreeekdkkrrdk..kkrdrrdkkrrrdk.kkddekkdrdk.",
            "...krrdkrrdk.krrdkrrdk.krrdkrrdk.krrddddkkkrrdk...krdrrdkkrrrdkkkkkkkeeerdk.",
            "...krrdkrrdk.krrdkrrdk.krrdkrrdk.krrdkkkk.krrdk...kkerddkkrdddkeeeekkkdrrdk.",
            "..kkrrdkrrdkkkrrdkrrdkkkrrdkrrdkkkrrdkk..kkrrdk.kkkkrddkkkrdkkkrrrrekkkrrdk.",
            "..kerreerrekkerrderrekkerreerrdkkerreekk.kerrekkkeeereeeeekdkkekrrrreeerddk.",
            "..kkrrrrdrrdkkrrdkrrddkkrrrrdrekkkrrrddk.kkrdddkkrdddrrrrddkkekdkddrrrdddkk.",
            "...kkddddkddkkkddkkddkkkkddddrrdkkkdddkk..kkdkkkkkdkkkddddkkkkdkkkkkdddkkk..",
            "....kkkkkkkkk.kkkkkkkk..kkeekrrdk.kkkkk....kkk...kkk.kkkkkk..kkk...kkkkk....",
            ".......................kkerrerddk...........................................",
            ".......................kekdrrrdkk...........................................",
            ".......................kkdkkdrdk............................................",
            "........................kkkkkrdk............................................",
            "............................krdk............................................",
            "............................kkdk............................................",
            ".............................kkk............................................"
        ]
    },
    chrome: {
        scale: 1,
        rows: [
            "..................................................",
            "...............................................w..",
            "............................##########.######.wyw.",
            "............................#ww##wwww###wwww##.w..",
            ".#############.##############ww#ww##ww#ww##ww#....",
            "##wwwww#wwwww###wwwww##wwww##ww#ww##ww#ww#####....",
            "#ss##ss#ss##ss#ss##ss#ss##ss#ss#ss##ss##ssss##....",
            "#gg##gg#gg##gg#gg##gg#gggggg#gg#gg##gg#####gg#....",
            "#ss##ss#ss##ss#ss##ss#ss#####ss#ss##ss#ss##ss#....",
            "##ppppp#pp##pp##ppppp##ppppp#pp##pppp###pppp##....",
            ".##################pp#################.######.....",
            "...............#ppppp#............................",
            "...............#######............................"
        ]
    }
};
function wordmark(name) {
    return wordmarks[name] ? wordmarks[name].rows : null;
}
function wordmarkScale(name) {
    return wordmarks[name] ? wordmarks[name].scale : 1;
}
