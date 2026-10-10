# Third-party parts

> TrollOS keeps this list from [AngelOS-Dotfiles](https://github.com/MixaDoDs/AngelOS-Dotfiles), trimmed to the parts that are in this repository.
> TrollOS's own additions (the splat logo, the wallpapers in `Pictures/wallpapers/TrollOS/`, the extra plugins) are © 2026 Flenstick under the MIT license;
> `extras/equicord/angelosFriends` is GPL-3.0-or-later.

Everything in this repository not listed here is © 2026 MixaDoDs under the MIT license
([`LICENSE`](LICENSE)). The parts below were made by others and keep their own licenses.

| What | Where | License | Source |
|---|---|---|---|
| SDDM theme *pixel-cyberpunk* (incl. its `bg.mp4`) | `sddm/themes/pixel-cyberpunk/` | GNU GPL v3 ([`LICENSE`](sddm/themes/pixel-cyberpunk/LICENSE)) | [Qylock](https://github.com/Darkkal44/qylock) by Darkkal44, unmodified |
| Pixelify Sans (the SDDM theme's font) | `sddm/themes/pixel-cyberpunk/font/` | SIL OFL 1.1 | [Pixelify Sans](https://github.com/eifetx/Pixelify-Sans) |
| Pixeloid Sans, Pixeloid Mono | `.local/share/fonts/pixel/` | SIL OFL 1.1 | GGBotNet |
| Cozette, CozetteVector | `.local/share/fonts/pixel/` | MIT (below) | [Cozette](https://github.com/slavfox/Cozette) by Ines |
| Pixora icon theme (`pixora`, `pixora-dark`) | `.local/share/icons/` | CC BY 4.0 | [tsora1603/pixora-icons](https://github.com/tsora1603/pixora-icons) by tsora1603 (based on Tux on Pixels by maxtron95, CC0; inspired by DeltaPixel). Included as obtained; no changes recorded in this repository. [License](https://creativecommons.org/licenses/by/4.0/) |
| Claude Companion plugin (a port) | `.config/quickshell/angelos/plugins/claude-companion/` | MIT (below) | [lowcache/noctalia-claude-plugin](https://github.com/lowcache/noctalia-claude-plugin) |

The SIL OFL 1.1 text with every font's copyright line: [`LICENSES/OFL-1.1.txt`](LICENSES/OFL-1.1.txt).

## Ideas, no code taken

The manifests credit these Noctalia plugins as the idea behind angelOS's own versions; their
code was not copied. Their licenses could not be checked (the repositories were not found):

- `cat` — idea: DotNetRob/cat (credited as MIT)
- `speedtest` — idea: nilsonlinux/speedtest-meter (credited as MIT)
- `web-search` — after notfinaldev/web-search (credited as MIT)

## Unclear — source unknown

These are in the repository, but where they come from and under what terms is not known.
Replace or remove them before relying on the repository being free to redistribute
(TrollOS already left out the three wallhaven.cc wallpapers listed upstream):

- `.config/quickshell/angelos/plugins/osu-mini/sfx/{hit,miss,perfect,break}.wav` — no source or generator recorded.

Not third-party: the angel's and the demon's sprites (`modules/y2k/sprites/`) are the author's;
all other sounds of angelOS are synthesised by `scripts/y2k-sounds.py`; the GIFs and screenshots in
`docs/` are recordings of angelOS in a clean demo stand (`scripts/demo/`), on a wallpaper drawn by
`scripts/demo/wallpaper.py`. NEEDY GIRL OVERDOSE and Undertale are only referenced
(names, a voice style made by the synthesiser) — none of their art or sound is included.

## Notices

### Cozette — MIT

```
MIT License

Copyright (c) 2020, Ines <ines@moonwit.ch>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### noctalia-claude-plugin (the Claude Companion port) — MIT

```
MIT License

Copyright (c) 2026 lowcache

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
