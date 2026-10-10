.pragma library

// A puppy Cerberus (26x13, facing right) — the cat plugin's hell look, the Wheel of
// Hell's runner (CerberusSprite draws it): '#' outline, 'f' fur,
// 'g' the heads (a shade lighter), 'r' red eyes, 'y' the flame on the tail, 'o' a
// tongue, 'w' the bone spikes of the collar. Five run frames, one asleep (zzz in 'y').
const cerberusRun = [
    [
        "..........#g##.#..........",
        "..........#ggg#g##........",
        "ryy......#gggr#ggg##......",
        "yy.......#ggg#gggr#g##....",
        "#f#......##gg#gggg#ggg#...",
        "#f#.#####f#####gg#gggrg#..",
        ".#f#fffffffffff###gggggg#.",
        "..#ffffffffffwffw##wgggg#.",
        "..#fffffffffffff#..####o..",
        "...#fffffffffff#..........",
        "....#####f######..........",
        "....#f#f##.#f##f#.........",
        ".....#.#....#..#.........."
    ],
    [
        "..........#g##.#..........",
        "..........#ggg#g##........",
        "ryy......#gggr#ggg##......",
        "yy.......#ggg#gggr#g##....",
        "#f#......##gg#gggg#ggg#...",
        "#f#.#####f#####gg#gggrg#..",
        ".#f#fffffffffff###gggggg#.",
        "..#ffffffffffwffw##wgggg#.",
        "..#fffffffffffff#..####o..",
        "...#fffffffffff#..........",
        "....#####f######..........",
        ".....#f#f#..#ff#..........",
        "......#.#....##..........."
    ],
    [
        "..........#g##.#..........",
        "..........#ggg#g##........",
        "ryy......#gggr#ggg##......",
        "yy.......#ggg#gggr#g##....",
        "#f#......##gg#gggg#ggg#...",
        "#f#.#####f#####gg#gggrg#..",
        ".#f#fffffffffff###gggggg#.",
        "..#ffffffffffwffw##wgggg#.",
        "..#fffffffffffff#..####o..",
        "...#fffffffffff#..........",
        "....#####f######..........",
        "....#f##f##f#.#f#.........",
        ".....#..#..#...#.........."
    ],
    [
        "..........#g##.#..........",
        "..........#ggg#g##........",
        "ryy......#gggr#ggg##......",
        "yy.......#ggg#gggr#g##....",
        "#f#......##gg#gggg#ggg#...",
        "#f#.#####f#####gg#gggrg#..",
        ".#f#fffffffffff###gggggg#.",
        "..#ffffffffffwffw##wgggg#.",
        "..#fffffffffffff#..####o..",
        "...#fffffffffff#..........",
        "...######f#####f#.........",
        "...#f#..###f#..#f#........",
        "....#....#.#....#........."
    ],
    [
        "..........#g##.#..........",
        "..........#ggg#g##........",
        "ryy......#gggr#ggg##......",
        "yy.......#ggg#gggr#g##....",
        "#f#......##gg#gggg#ggg#...",
        "#f#.#####f#####gg#gggrg#..",
        ".#f#fffffffffff###gggggg#.",
        "..#ffffffffffwffw##wgggg#.",
        "..#fffffffffffff#..####o..",
        "...#fffffffffff#..........",
        "....#####f######..........",
        ".....#ff##.#ff#...........",
        "......##....##............"
    ]
];

const cerberusSleep = [
    ".........................y",
    ".......................y..",
    "......................y...",
    "........................y.",
    "............#.............",
    "...........#g##.#.........",
    "...........#ggg#g##.#.....",
    "r...#######ggg##ggg#g##...",
    "yy.#ffffff#ggg#ggg##ggg#..",
    "#f#ffffffff#gg#ggg#ggg#g#.",
    ".#f#ffffffff####gg#gggggg#",
    "..######ffff########ggggg#",
    "........####........#####."
];

function cerberus(i) {
    return cerberusRun[i % cerberusRun.length];
}
