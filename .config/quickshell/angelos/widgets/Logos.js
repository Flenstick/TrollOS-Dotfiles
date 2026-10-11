.pragma library

// angelOS logos (widgets/AngelLogo.qml; Settings → Bar → Logo). ASCII bitmaps in the
// Icons.js alphabet ('#' ink, 'o' accent, 'x' accent2, 'y' gold, 'w' white, 'f' lavender,
// 'r' red) plus a few colours of their own that AngelLogo passes as a palette.

// ---- emblems: 19 wide; the first `halo` rows are the halo (horns while the demon rules) ----
const emblems = {
    // TrollOS Inferno: the inverted pentagram, a blood star in a gold circle (no halo, no horns)
    pentagram: {
        halo: 0,
        rows: [
            "....xxxxx....",
            "..xx.....xx..",
            ".xxr.....rxx.",
            ".x.rrr.rrr.x.",
            "x...rrrrr...x",
            "x...r...r...x",
            "x.rrr...rrr.x",
            "xrrrrrrrrrrrx",
            "x....r.r....x",
            ".x...r.r...x.",
            ".xx...r...xx.",
            "..xx..r..xx..",
            "....xxxxx...."
        ]
    },
    // the same in a dark-red circle
    pentagramRed: {
        halo: 0,
        rows: [
            "....#####....",
            "..##.....##..",
            ".##r.....r##.",
            ".#.rrr.rrr.#.",
            "#...rrrrr...#",
            "#...r...r...#",
            "#.rrr...rrr.#",
            "#rrrrrrrrrrr#",
            "#....r.r....#",
            ".#...r.r...#.",
            ".##...r...##.",
            "..##..r..##..",
            "....#####...."
        ]
    },
    // TrollOS Inferno: the inverted cross, red with a dark-red rim
    cross: {
        halo: 0,
        rows: [
            "....###....",
            "....#r#....",
            "....#r#....",
            "....#r#....",
            "....#r#....",
            "....#r#....",
            "....#r#....",
            "#####r#####",
            "#rrrrrrrrr#",
            "#####r#####",
            "....#r#....",
            "....#r#....",
            "....###...."
        ]
    },
    // TrollOS desktop layouts: the bat and the moon (Vampire), Baphomet (Satanic), the ring and
    // the eclipse (Void) — ~/Projects/trollos-wordmark/emblems.py
    bat: {
        halo: 0,
        rows: [
            "#####...#####...#####",
            "#xxx###.#x#x#.###xxx#",
            "#xxxxx###xxx###xxxxx#",
            "#xxxxxxxxoxoxxxxxxxx#",
            "#x##x#xxxxxxxxx#x##x#",
            "######x#xxxxx#x######",
            ".....####xxx####.....",
            "........#xxx#........",
            "........#####........",
            "....................."
        ]
    },
    baphomet: {
        halo: 0,
        rows: [
            "#...........#",
            "##.........##",
            ".#x#.....#x#.",
            "..#x#...#x#..",
            "...#x###x#...",
            "..#xxxxxxx#..",
            ".#x#oxxxo#x#.",
            "#xx#xxxxx#xx#",
            ".##.#xxx#.##.",
            "....#xxx#....",
            "....#x#x#....",
            ".....#x#.....",
            "......#......"
        ]
    },
    moon: {
        halo: 0,
        rows: [
            "...####......",
            "..##xx#......",
            ".##xx##......",
            "##xxx#.......",
            "#xxxx#.......",
            "#xxxx#.......",
            "#xxxx#.......",
            "#xxxx##......",
            "#xxxxx###....",
            "##xxxxxx###..",
            ".##xxxxxxx#..",
            "..##xxxxx##..",
            "...#######..."
        ]
    },
    ring: {
        halo: 0,
        rows: [
            "...#######...",
            ".###wwwww###.",
            ".#wwwwwwwww#.",
            "##ww#####ww##",
            "#ww##...##ww#",
            "#ww#.....#ww#",
            "#ww#.....#ww#",
            "#ww#.....#ww#",
            "#ww##...##ww#",
            "##ww#####ww##",
            ".#wwwwwwwww#.",
            ".###wwwww###.",
            "...#######..."
        ]
    },
    eclipse: {
        halo: 0,
        rows: [
            "..#########..",
            ".##wxxxxww##.",
            "##wx.....xw##",
            "#wx........w#",
            "#x.........w#",
            "#x..........#",
            "#x..........#",
            "#x..........#",
            "#w..........#",
            "#wx........w#",
            "##ww......w##",
            ".##ww...ww##.",
            "..#########.."
        ]
    },
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
// TrollOS Inferno: «TrollOS» (~/Projects/trollos-wordmark/marks.py) — готика Jacquard 24 кровью
// с каплями или без, и пиксельный капслок цвета кости; палитра — AngelLogo (r d k e s)
Object.assign(wordmarks, {
    infernoDrip: {
        scale: 0.5,
        rows: [
            "....kkkkkkkk....kkk.................kkk...kkk..kkkkkkk..kkkk....kkkkkk.kkk..",
            "...kkeeeeeekkkkkkekk...............kkekk.kkekkkkeeekekk.keekk.kkkeeeekkkekk.",
            "..kkerrrrrreeeeeekdk...............kerdk.kerdkkerrrerdkkkrrekkkeerrrreeerdk.",
            "..kekdddddrrrdrdddkk...............krrdk.krrdkkrdrrrddeeerrrekkrrddrrrrrddk.",
            "..krdkkkkkkdrdrdkkk................krrdk.krrdkkkdkdrderdddrrrdkrrdkkdrrddkk.",
            "..kkeekkkkkerdrdk.kkkkkkk..kkkkk...krrdk.krrdk.kkkkrdrrdkkrrrdkrreekkkddkk..",
            "..kerreekeerrdrdkkkekeeekkkkeeekkk.krrdk.krrdk..keerdrrdkkrrrdkrrrrekkkkk...",
            "..kkdrrrdkdrrdrdkkerekrrdkkekrreekkkrrdk.krrdk..kkdrdrrdkkrrrdkrdddreekkk...",
            "...kkrrrdeerrdrdkkkrrdkddkerdkrrddkkrrdk.krrdk..keerdrrdkkrrrdkkekkkdreekk..",
            "....krrrdkdrrdrdk.krrdkkkkrrdkrrdkkkrrdk.krrdk..kkdrdrrdkkrrrdkkkeeekkrrekk.",
            "....krrrdkkrrdrdk.krrdk..krrdkrrdk.krrdk.krrdk...kkrdrrdkkrrrdk.kkddekkdrdk.",
            "....krrrdkkrrdrdk.krrdk..krrdkrrdk.krrdk.krrdk....krdrrdkkrrrdkkkkkkkeeerdk.",
            "....kkrrdkkrrdrdk.krrdk..krrdkrrdk.krrdk.krrdk....kkerddkkrdddkeeeekkkdrrdk.",
            ".....krrekerddrdkkkrrdk.kkrrdkrrdkkkrrdkkkrrdk..kkkkrddkkkrdkkkrrrrekkkrrdk.",
            ".....krdrekddekdkkerrdk.kerreerddkkerrekkerrekk.keeereeeeekdkkekrrrreeerddk.",
            ".....krdkreeekdkkkkrrdk.kkrrrrddkkkrrdddkkrdrdk.krdddrrrrddkkekdkddrrrdddkk.",
            ".....krdkkddddkk..kkddk..kkddddkk.krddkkkkkdrdk.kkdkkkddddkkkkdkkkkkrddkkk..",
            ".....kkdkkkkkkk....kkkk...kkkkkk..kkdkk...kkrdk..kkk.kkkkkk..kkk...krdkk....",
            "......kkk..........................kkk.....krdk....................kkdk.....",
            "...........................................kkdk.....................kkk.....",
            "............................................kkk............................."
        ]
    },
    infernoGothic: {
        scale: 0.5,
        rows: [
            "....kkkkkkkk....kkk.................kkk...kkk..kkkkkkk..kkkk....kkkkkk.kkk..",
            "...kkeeeeeekkkkkkekk...............kkekk.kkekkkkeeekekk.keekk.kkkeeeekkkekk.",
            "..kkerrrrrreeeeeekdk...............kerdk.kerdkkerrrerdkkkrrekkkeerrrreeerdk.",
            "..kekdddddrrrdrdddkk...............krrdk.krrdkkrdrrrddeeerrrekkrrddrrrrrddk.",
            "..krdkkkkkkdrdrdkkk................krrdk.krrdkkkdkdrderdddrrrdkrrdkkdrrddkk.",
            "..kkeekkkkkerdrdk.kkkkkkk..kkkkk...krrdk.krrdk.kkkkrdrrdkkrrrdkrreekkkddkk..",
            "..kerreekeerrdrdkkkekeeekkkkeeekkk.krrdk.krrdk..keerdrrdkkrrrdkrrrrekkkkk...",
            "..kkdrrrdkdrrdrdkkerekrrdkkekrreekkkrrdk.krrdk..kkdrdrrdkkrrrdkrdddreekkk...",
            "...kkrrrdeerrdrdkkkrrdkddkerdkrrddkkrrdk.krrdk..keerdrrdkkrrrdkkekkkdreekk..",
            "....krrrdkdrrdrdk.krrdkkkkrrdkrrdkkkrrdk.krrdk..kkdrdrrdkkrrrdkkkeeekkrrekk.",
            "....krrrdkkrrdrdk.krrdk..krrdkrrdk.krrdk.krrdk...kkrdrrdkkrrrdk.kkddekkdrdk.",
            "....krrrdkkrrdrdk.krrdk..krrdkrrdk.krrdk.krrdk....krdrrdkkrrrdkkkkkkkeeerdk.",
            "....kkrrdkkrrdrdk.krrdk..krrdkrrdk.krrdk.krrdk....kkerddkkrdddkeeeekkkdrrdk.",
            ".....krrekerddrdkkkrrdk.kkrrdkrrdkkkrrdkkkrrdk..kkkkrddkkkrdkkkrrrrekkkrrdk.",
            ".....kkdrekddekdkkerrdk.kerreerddkkerrekkerrekk.keeereeeeekdkkekrrrreeerddk.",
            "......kkkreeekdkkkkrrdk.kkrrrrddkkkkrdddkkrdddk.krdddrrrrddkkekdkddrrrdddkk.",
            "........kkddddkk..kkddk..kkddddkk..kkdkkkkkdkkk.kkdkkkddddkkkkdkkkkkdddkkk..",
            ".........kkkkkk....kkkk...kkkkkk....kkk...kkk....kkk.kkkkkk..kkk...kkkkk...."
        ]
    },
    infernoCaps: {
        scale: 1,
        rows: [
            ".dddddddddddddd.dddddddddd...dddd...........dddddd.dddddd..",
            ".dssssssdsssssdddssssddssd...dssd..........ddssssdddssssdd.",
            ".dddssdddssddssdssddssdssd...dssd..........dssddssdssddssd.",
            "...dssd.dssddssdssddssdssd...dssd......e.e.dssddssdssddddd.",
            "...dssd.dsssssddssddssdssd...dssd.......e..dssddssddssssdd.",
            "...dssd.dssssdddssddssdssd...dssd.......e..dssddssdddddssd.",
            "...dssd.dssdssddssddssdssdddddssddddd......dssddssdssddssd.",
            "...dssd.dssddssddssssddssssssdssssssd......ddssssdddssssdd.",
            "...dddd.ddddddddddddddddddddddddddddd.......dddddd.dddddd.."
        ]
    },
    infernoNeon: {
        scale: 1,
        rows: [
            ".dddddddddd..........dddddddddddddddddddddd..",
            ".drrrrrrrrd..........drrrrrrrrrrrrrdrrrrrrdd.",
            ".dreeeeeerddddddddddddreereerreeeerrreeeerrd.",
            ".drrreerrrrrrrrrrrrrrrreereereerreereerreerd.",
            ".dddreerdreereerreeeerreereereerreereerrrrrd.",
            "...dreerdreeeerreerreereereereerreerreeeerrd.",
            "...dreerdreeerrreerreereereereerreerrrrreerd.",
            "...dreerdreerrdreerreereereereerreereerreerd.",
            "...dreerdreerddrreeeerreereerreeeerrreeeerrd.",
            "...drrrrdrrrrdddrrrrrrrrrrrrrrrrrrrdrrrrrrdd.",
            "...ddddddddddd.dddddddddddddddddddddddddddd.."
        ]
    },
    infernoHorns: {
        scale: 1,
        rows: [
            "ddd.....................ddd.......................",
            "drdd...................ddrd.......................",
            "ddrdd.................ddrdd.......................",
            ".drrdd...............ddrrd....................ddd.",
            ".ddrrddddd...........drrddddddddddd.dddddd...ddrdd",
            "..dssssssd...........ddssdssddssssdddssssdd.ddrrrd",
            "..dddssddddddddddddddddssdssdssddssdssddssd.drrrdd",
            "....dssd.dssdssddssssddssdssdssddssdssddddd.ddrrd.",
            "....dssd.dssssddssddssdssdssdssddssddssssddddrddd.",
            "....dssd.dsssdddssddssdssdssdssddssdddddssddrdd...",
            "....dssd.dssdd.dssddssdssdssdssddssdssddssrrdd....",
            "....dssd.dssd..ddssssddssdssddssssdddssssdddd.....",
            "....dddd.dddd...ddddddddddddddddddd.dddddd........"
        ]
    },
    infernoEmo: {
        scale: 1,
        rows: [
            "...kkk....................................",
            ".kkkrkkk..................................",
            ".krrrrrk............kkkkkkk...............",
            ".kkkrkkk............ksskssk...............",
            "...krk.kkkkkkkkkkkkkkssksskkkkkkkkkkkkkkk.",
            "...krk.kssksskksssskkssksskksssskkssssssk.",
            "...krk.ksssskksskkssksskssksskkssksskkkkk.",
            "...krk.kssskkksskkssksskssksskksskssssssk.",
            "...krk.ksskk.ksskkssksskssksskksskkkkkssk.",
            "...krk.kssk..kksssskkssksskksssskkssssssk.",
            "...kkk.kkkk...kkkkkkkkkkkkkkkkkkkkkkkkkkk."
        ]
    },
    infernoBone: {
        scale: 0.5,
        rows: [
            "....kkkkkkkk....kkk.................kkk...kkk..kkkkkkk..kkkk....kkkkkk.kkk..",
            "...kksssssskkkkkkskk...............kkskk.kkskkkkssskskk.ksskk.kkksssskkkskk.",
            "..kkssssssssssssskrkk..............kssrkkkssrkkssssssrkkkssskkkssssssssssrkk",
            "..kskrrrrrsssrsrrrkrk..............kssrrkkssrrksrsssrrssssssskkssrrsssssrrrk",
            "..ksrkrrrrrrsrsrrrrkk..............kssrrkkssrrkkrrrsrssrrrsssrkssrrrrssrrrrk",
            "..kksskkkkkssrsrrkkkkkkkk..kkkkk...kssrrkkssrrkkkrksrssrrrsssrrsssskkrrrrrkk",
            "..kssssskssssrsrrkkskssskkkkssskkk.kssrrkkssrrk.ksssrssrrksssrrssssskkkrrkk.",
            "..kkrsssrkrssrsrrkssskssrkksksssskkkssrrkkssrrk.kkrsrssrrksssrrsrrrssskkkk..",
            "...kksssrssssrsrrkkssrkrrrssrkssrrkkssrrkkssrrk.ksssrssrrksssrrksrrrrssskk..",
            "....ksssrrrssrsrrkkssrrkrrssrrssrrrkssrrkkssrrk.kkrsrssrrksssrrkkssskrssskk.",
            "....ksssrrkssrsrrkkssrrkkkssrrssrrkkssrrkkssrrk..kksrssrrksssrrkkkrrskkrsrkk",
            "....ksssrrkssrsrrkkssrrk.kssrrssrrkkssrrkkssrrk...ksrssrrksssrrkkkkrrssssrrk",
            "....kkssrrkssrsrrkkssrrk.kssrrssrrkkssrrkkssrrk...kkssrrrksrrrrsssskkkrssrrk",
            ".....ksssrssrrsrrkkssrrkkkssrrssrrkkssrrkkssrrk.kkkksrrrrksrrrrssssskkkssrrk",
            ".....kkrsskrrsrrrksssrrkkssssssrrrkssssrkssssrk.kssssssssskrrkskssssssssrrrk",
            "......kkrssssrrkrkkssrrkkkssssrrrrkksrrrkksrrrkkksrrrssssrrkrskrkrrsssrrrrrk",
            ".......kkkrrrrkrkkkkrrrk.kkrrrrrrkkkkrrrrkkrrrrkkkrrrrrrrrrrkkrkrkrrrrrrrrkk",
            ".........kkrrrrkk..kkrrk..kkrrrrkk..kkrkkkkkrkkk.kkrkkkrrrrkkkkrkkkkkrrrkkk.",
            "..........kkkkkk....kkkk...kkkkkk....kkk...kkk....kkk.kkkkkk..kkk...kkkkk..."
        ]
    }
});
// TrollOS desktop layouts: words for the Start button without «TrollOS» (~/Projects/trollos-wordmark/words.py)
Object.assign(wordmarks, {
    infernoWord: {
        scale: 0.5,
        rows: [
            "...kkkkkkkkkkkk.............kkk......................................",
            "..kkeeeeekkekekk...........kkekk.....................................",
            "..kekddrreekdrdk...........kerekk....................................",
            "..kkdkkkdddeekdk..........kkrrrekk...................................",
            "...kkk.kkkkrrdkk..........kerdrddk...................................",
            "........kekrrdk.kkk.kkkk.kkrrdkdkkkkkkk.kkkkkkk.kkk.kkkk....kkkkk....",
            "........krdrrdkkkekkkeekkkerreekkkkeeekkkekeeekkkekkkeekk..kkeeekkk..",
            ".....kkkkrdrrdkkereeerrekkkrrdddkkerrrdkerekrrdkereeerrekkkkekrreekk.",
            ".....keeerdrrdkkkrrddrrddkkrrdkkkerddrekkrrdkddkkrrddrrddkkerdkrrddk.",
            ".....kkddrdrrdk.krrdkrrdkkkrrdk.krrdkkrdkrrdkkkkkrrdkrrdkkkrrdkrrdkk.",
            ".....keeerdrrdk.krrdkrrdk.krrdk.krreeekdkrrdk...krrdkrrdk.krrdkrrdk..",
            ".....kkddrdrrdk.krrdkrrdk.krrdk.krrddddkkrrdk...krrdkrrdk.krrdkrrdk..",
            "......kkkrdrrdk.krrdkrrdk.krrdk.krrdkkkkkrrdk...krrdkrrdk.krrdkrrdk..",
            "...kkkkkkrdrrdkkkrrdkrrdkkkrrdkkkrrdkk.kkrrdk..kkrrdkrrdkkkrrdkrrdk..",
            "..kkeeeeekekddkkerrderrekkerrekkerreekkkerrdk..kerrderrekkerreerddk..",
            "..kekdrrrekdkkkkkrrdkrrddkkrdddkrrrrddkkkrrdk..kkrrdkrrddkkrrrrddkk..",
            "..kkdkrddddkk...kkddkkddkkkkdkkkrddddkk.kkddk...kkddkkddkkkkddrdkk...",
            "...kkkrdkkkk.....kkkkkkkk..kkk.kkdkkkk...kkkk....kkkkkkkk..kkkrdk....",
            ".....krdk.......................kkk..........................kkdk....",
            ".....kkdk.....................................................kkk....",
            "......kkk............................................................"
        ]
    },
    inferno666: {
        scale: 0.5,
        rows: [
            ".....kkk....kkk.....kkk....",
            ".....kekk...kekk....kekk...",
            "...kkkrdk.kkkrdk..kkkrdk...",
            "..kkeerekkkeerekkkkeerekk..",
            "..kerdrddkerdrddkkerdrddk..",
            "..krrdkdkkrrdkdkkkrrdkdkk..",
            "..krrdkkkkrrdkkk.krrdkkk...",
            "..krreekkkrreekk.krreekk...",
            "..krrdrekkrrdrekkkrrdrekk..",
            "..krrdrrekrrdrrekkrrdrrekk.",
            "..krrdrrrdrrdrrrdkrrdrrrdk.",
            "..krrdrrrdrrdrrrdkrrdrrrdk.",
            "..krrdrrrdrrdrrrdkrrdrrrdk.",
            "..krrerrddrrerrddkrrerrddk.",
            "..kkrrdddkkrrdrdkkkrrdrdkk.",
            "...krddkkkkkrdrdk.kkddrdk..",
            "...krdkk...krdrdk..kkkkdk..",
            "...krdk....kkdrdk.....kkk..",
            "...kkdk.....kkkdk..........",
            "....kkk.......kkk.........."
        ]
    },
    vampireWord: {
        scale: 0.5,
        rows: [
            "..kkkkkk.kkkkkkkk.........................................................",
            "..kekeekkkeeekkekk..................................kkkk..................",
            "..krerrekkrrrdkrdk..................................keekk.................",
            "..kkrrrreekrreekdk..................................krrdk.................",
            "...kkdrrrrekrrddkk..................................kkddk.................",
            "...kkkrrrdrdrrdkkkkkkkkk..kkk.kkkkkkkk...kkkkkkkk...kkkkkkkkkkkk..kkkkk...",
            "...keerrrdrdrrdk.keeeeekkkkekkkeekkeekkk.keekkeekk.kkekkkkekeeekkkkeeekk..",
            "...kkdrrrdrdrrdkkkrddrrekkereeerreerreekkkrrdkrrekkkereekerekrrdkkerrrdk..",
            "...keerrrdrdrrdkkerdkrrddkkrrddrrdddrrddkerreerrrekkkrrddkrrdkddkerddrekk.",
            "...kkdrrrdrdrrdkkrrdkrrdkkkrrdkrrdkkrrdkkkrrdddrrddkkrrdkkrrdkkkkrrdkkrdk.",
            "....kkrrrdrdrrdkkrrdkrrdk.krrdkrrdkkrrdk.krrdkkrrdkkkrrdkkrrdk..krreeekdk.",
            ".....krrrdrdrddkkrrdkrrdk.krrdkrrdkkrrdk.krrdkkrrdk.krrdkkrrdk..krrddddkk.",
            "...kkkkdddrekdkkkrrdkrrdk.krrdkrrdkkrrdk.krrdkkrrdk.krrdkkrrdk..krrdkkkk..",
            "..kkeeeeekrddkkkkrrdkrrdkkkrrdkrrdkkrrdkkkrrdkkrrdkkkrrdkkrrdk.kkrrdkk....",
            "..kerrrrrekdkk.kerreerrekkerrderreeerrekkerreeerrekkerrekerrdk.kerreekk...",
            "..krddrrrddkk..kkrrrrdrrdkkrrdkrrdddrrddkrrrdddrdddkkrrddkrrdk.kkrrrddk...",
            "..kkdkkdddkk....kkddddkddkkkddkkddkkkddkkkrrdkkkdkkkkkddkkkddk..kkdddkk...",
            "...kkkkkkkk......kkkkkkkkk.kkkkkkkk.kkkk.krrdk.kkk...kkkk.kkkk...kkkkk....",
            ".........................................krddk............................",
            ".........................................krdkk............................",
            ".........................................kkdk.............................",
            "..........................................kkk............................."
        ]
    },
    vampireNocturne: {
        scale: 0.5,
        rows: [
            "....kkkkk.kkkkkkkk.............................................................",
            "...kkeeekkkeeekkekk.................kkk........................................",
            "..kkerrrekekrreekdk................kkekk.......................................",
            "..kekdrrrekdkrrddkk................kerdk.......................................",
            "..kkdkkrrdekkrrdkk.................krrdk.......................................",
            "...kkkkrrdrdkrrdk...kkkkk.....kkkkkkrrdkk.kkk..kkk..kkkkkkkkkk.kkkk....kkkkk...",
            "....keerrdrdkrrdk..kkeeekkk..kkeeekerreekkkekkkkekkkkekeeekkekkkeekk..kkeeekk..",
            "....kkdrrdrdkrrdk.kkekrreekkkkekrrdkrrdddkerekeerekkerekrrdereeerrekkkkerrrdk..",
            "....keerrdrdkrrdk.kerdkrrddkkerdkddkrrdkkkkrrdkrrddkkrrdkddkrrddrrddkkerddrekk.",
            "....kkdrrdrdkrrdk.krrdkrrdkkkrrdkkkkrrdk..krrdkrrdkkkrrdkkkkrrdkrrdkkkrrdkkrdk.",
            ".....kkrrdrdkrrdk.krrdkrrdk.krrdk..krrdk..krrdkrrdk.krrdk..krrdkrrdk.krreeekdk.",
            "......krrdrdkrrdk.krrdkrrdk.krrdk..krrdk..krrdkrrdk.krrdk..krrdkrrdk.krrddddkk.",
            "....kkkkddrdkrrdk.krrdkrrdk.krrdk..krrdk..krrdkrrdk.krrdk..krrdkrrdk.krrdkkkk..",
            "..kkkeeekkrdkrrdkkkrrdkrrdkkkrrdkkkkrrdkkkkrrdkrrdkkkrrdk.kkrrdkrrdkkkrrdkk....",
            "..keerrreekdkrrekkerreerddkkerreekkerreekkerreerrekkerrdk.kerrderrekkerreekk...",
            "..krddrrrddkkkrddkkrrrrddkkkkrrrddkkdrrddkkrrddrrddkkrrdk.kkrrdkrrddkkrrrddk...",
            "..kkdkkdddkk.kkdkkkkddddkk..kkdddkkkkkddkkkkddkkddkkkkddk..kkddkkddkkkkdddkk...",
            "...kkkkkkkk...kkk..kkkkkk....kkkkk...kkkk..kkkkkkkk..kkkk...kkkkkkkk..kkkkk...."
        ]
    },
    voidWord: {
        scale: 1,
        rows: [
            ".............s.....s.",
            "...................s.",
            ".s...s..sss..s..ss.s.",
            ".s...s.s...s.s.s..ss.",
            ".s...s.s...s.s.s...s.",
            "..s.s..s...s.s.s..ss.",
            "...s....sss..s..ss.s."
        ]
    },
    voidCaps: {
        scale: 1,
        rows: [
            ".ss..ss.....ssss.....ssss....ssss...",
            ".ss..ss....ss..ss.....ss.....ss.ss..",
            ".ss..ss....ss..ss.....ss.....ss..ss.",
            "..ssss.....ss..ss.....ss.....ss..ss.",
            "..ssss.....ss..ss.....ss.....ss..ss.",
            "...ss......ss..ss.....ss.....ss.ss..",
            "...ss.......ssss.....ssss....ssss..."
        ]
    }
});

function wordmark(name) {
    return wordmarks[name] ? wordmarks[name].rows : null;
}
function wordmarkScale(name) {
    return wordmarks[name] ? wordmarks[name].scale : 1;
}
