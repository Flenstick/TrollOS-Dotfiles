.pragma library

// Pixel art for the range. PxIcon colors: # ink, o fill, x fill2, y fill3,
// w light, f body, r bad. People: # hair/eyes/shoes, y skin, o shirt, x pants.

var W = 8;
var H = 12;
var HEAD_ROWS = 5;

var RUN_A = [
    "...###..",
    "..#####.",
    "..#yy#y.",
    "..#yyyy.",
    "...yyy..",
    "..oooo..",
    ".ooooooy",
    "y.oooo..",
    "..xxxx..",
    "..xx.xx.",
    ".xx...x.",
    ".#....##"
];

var RUN_B = [
    "...###..",
    "..#####.",
    "..#yy#y.",
    "..#yyyy.",
    "...yyy..",
    "..oooo..",
    "..oooo..",
    "..oyoo..",
    "..xxxx..",
    "...xx...",
    "...xx...",
    "...###.."
];

var DEAD = [
    "...###..",
    "..#####.",
    "..#yy#y.",
    "..#yyyy.",
    "...yyy..",
    "..oooo..",
    ".yorroy.",
    "..orro..",
    "..xxxx..",
    "..xx.xx.",
    "..xx.xx.",
    "..##.##."
];

var DEAD_HEAD = [
    "...#r#..",
    "..#rr##.",
    "..#yrry.",
    "..#yyry.",
    "...yyy..",
    "..oooo..",
    ".yooooy.",
    "..oooo..",
    "..xxxx..",
    "..xx.xx.",
    "..xx.xx.",
    "..##.##."
];

// facing right; f = metal, w = highlight
var GUN = [
    "############.",
    "#wwwwwwwwwww#",
    "#fffffffffff#",
    "#fff#########",
    "#fff#.#..#...",
    "#fff#..##....",
    "#fff#........",
    "#####........"
];

// the same pistol in a fist, with a sleeve (o)
var GUN_HAND = [
    "############.",
    "#wwwwwwwwwww#",
    "#fffffffffff#",
    "#fff#########",
    "yyyyy.#..#...",
    "yyyy#yy#.....",
    "#yyy#........",
    ".yyy.........",
    "oooo.........",
    "oooo........."
];

// Geiger counter: probe on the left (f metal, w light), yellow body (o),
// display (x), meter (y), LED (r)
var GEIGER = [
    ".....##########",
    ".....#oooooooo#",
    "####.#o######o#",
    "#ww###o#xxxx#o#",
    "#fffffo#xxxx#o#",
    "####.#o######o#",
    ".....#oyyyooro#",
    ".....#oooooooo#",
    ".....##########"
];

var CROSS = [
    "...w...",
    "...w...",
    ".......",
    "ww.r.ww",
    ".......",
    "...w...",
    "...w..."
];

var FLASH = [
    "..y..",
    "y.yy.",
    ".ywyy",
    "y.yy.",
    "..y.."
];

var BULLET = [
    ".y.",
    "yyy",
    "ooo",
    "ooo",
    "ooo"
];

var SHIRTS = ["#e05252", "#4f8ef7", "#3fbf6f", "#f2b33d", "#a26bf0", "#ff7ac0", "#f4f4f4", "#2fc6c6", "#ff8a3d"];
var PANTS = ["#2b3a67", "#3b3b3b", "#5a4632", "#1f5f4a", "#6b6f7a"];
var SKIN = ["#f6d2b0", "#e8b48f", "#c68a5f", "#8d5a3b"];
var HAIR = ["#2a1c14", "#4a2d1a", "#d9a74a", "#111111", "#9a3b22", "#c9c9c9"];
var SCREAMS = ["ААА!", "НЕ НАДО!", "МАМА!", "ПОМОГИТЕ!", "!!!", "БЕЖИМ!", "ОН С ПУШКОЙ!"];

function pick(list) {
    return list[Math.floor(Math.random() * list.length)];
}
