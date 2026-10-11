.pragma library

// Чёрный котик в бинтах — как вязаная игрушка: огромная голова, бинт наискосок с
// пятнами крови и сердечком, один белый глаз, левая лапка забинтована. 18×13, анфас.
// '#' обводка-подсветка (тёмный акцент: на тёмной панели чёрный кот иначе пропадёт),
// 'f' чёрная шерсть, 'w' бинт, 'r' кровь, 'h' сердечко, 'e' глаз, 'm' ротик / закрытый глаз.
// Нарисован по маске, обводка — автоматом (рисовалка была в scratchpad, итог — здесь).

const sit = [
    ".#..............#.",
    "#f#............#f#",
    "#ff#..........#ff#",
    "#fff##########fff#",
    "#fffwwwrfffffffff#",
    "#fffffwwrwwffffff#",
    "#feefffffwwwwffff#",
    "#feefffffffwrwhhf#",
    ".#ffffffmfffffhw#.",
    "..#ffffffffffff#..",
    "...#ffffffffff#...",
    "..#wrww####ffff#..",
    "...####....####..."
];

const stepLeft = [
    ".#..............#.",
    "#f#............#f#",
    "#ff#..........#ff#",
    "#fff##########fff#",
    "#fffwwwrfffffffff#",
    "#fffffwwrwwffffff#",
    "#feefffffwwwwffff#",
    "#feefffffffwrwhhf#",
    ".#ffffffmfffffhw#.",
    "..#ffffffffffff#..",
    "..##ffffffffff##..",
    ".#wrww######ffff#.",
    "..####......####.."
];

const stepRight = [
    ".#..............#.",
    "#f#............#f#",
    "#ff#..........#ff#",
    "#fff##########fff#",
    "#fffwwwrfffffffff#",
    "#fffffwwrwwffffff#",
    "#feefffffwwwwffff#",
    "#feefffffffwrwhhf#",
    ".#ffffffmfffffhw#.",
    "..#ffffffffffff#..",
    "...#ffffffffff#...",
    "...#wrww##ffff#...",
    "....####..####...."
];

const sleep = [
    ".#..............#.",
    "#f#............#f#",
    "#ff#..........#ff#",
    "#fff##########fff#",
    "#fffwwwrfffffffff#",
    "#fffffwwrwwffffff#",
    "#ffffffffwwwwffff#",
    "#fmmfffffffwrwhhf#",
    ".#ffffffmfffffhw#.",
    "..#ffffffffffff#..",
    "...############..."
];

// мурчит: глазки ^ ^, румянец, ротик «w»
const purr = [
    ".#..............#.",
    "#f#............#f#",
    "#ff#..........#ff#",
    "#fff##########fff#",
    "#fffwwwrfffffffff#",
    "#fffffwwrwwffffff#",
    "#fmmfffffwwwwffff#",
    "#mffmffffffwrwhhf#",
    ".#hhfffmfmffffhw#.",
    "..#fffffmfffffff#.",
    "...#ffffffffff#...",
    "..#wrww####ffff#..",
    "...####....####..."
];
// ушки дёргаются от удовольствия
const purr2 = purr.slice();
purr2[0] = "..#............#..";
purr2[1] = ".#f#..........#f#.";

// бег: сидит → шаг левой → сидит → шаг правой (подпрыгивает на шагах — CatSprite)
function run(i) {
    return [sit, stepLeft, sit, stepRight][i % 4];
}
