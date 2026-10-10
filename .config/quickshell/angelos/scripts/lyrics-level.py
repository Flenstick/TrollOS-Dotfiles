#!/usr/bin/env python3
"""How bright the lyrics on the bar are (services/LyricsGlow.qml): a level, read live.

  lyrics-level.py stream <player stream>
      The player's own output (a PipeWire stream node: serial or name), after its
      slider in the mixer. Prints {"db": RMS level in dBFS}, smoothed: fast up, slow
      down — quiet parts of a song and a lower slider both dim the line.

  lyrics-level.py rode <player stream> <mix source> [<pos>,<pos>]
      RØDECaster: where the fader of the music stands, read from the sound itself.
      The player's stream is what the computer sends; the mix source (the console's
      main mix, after its faders — e.g. the "pro-input-0" source, or two AUX channels of
      the multitrack one) is what comes back. The fader's gain is the projection of
      the mix onto the music, read on 20 ms loudness envelopes (the console's input
      and output clocks drift apart, waveforms don't line up for long): mix energy =
      g² · music energy + the rest, and the rest (the mic, chat, games) does not
      follow the music's beat. The delay through the console is found by
      correlating the envelopes every few seconds. The music quiet or a steady
      drone: the last value holds; the music playing but nowhere in the mix: the
      fader is down.
      Prints {"db": gain in dB, "lag": samples}.

      That mix also carries the mic, and talking over the music swamped the beat:
      the line dimmed on every word. So when the mix source is the console's main
      one (no AUX pair given, or the multitrack's own AUX0/1) and the console has a
      multitrack source next to it
      (same card, more than two channels: the mix in AUX0/1, every fader's track
      after it in pairs, the tracks before their faders), that is read instead, in
      one capture, sample for sample: the mix = Σ gain · track, solved by least
      squares, so the voice is just another track with its own gain. The player's
      track is the one whose loudness follows the player's; the line follows that
      track's gain times its level over the player's — the same number as above.
      Prints {"db": ..., "lag": blocks, "track": "AUX4/5"}.
      Another pair of the multitrack given: that is the player's track, nothing to
      find. The tracks of a RØDECaster Duo come before their faders, so reading the
      pair itself as the mix (as below) told nothing about the fader.

One JSON line whenever the value moves by 1 dB or more, at most twice a second (each
line restyles the bar, and the bar repaints at the screen's rate while it eases);
{"error": "..."} and exit 2 when a capture can't start or ends. The RØDE mode needs
numpy; the stream mode also runs on plain Python at a lower rate.
"""
import json
import math
import os
import shutil
import signal
import subprocess
import sys
import threading
import time

try:
    import numpy as np
except ImportError:  # the stream mode still works
    np = None

FLOOR_DB = -90.0
RATE = 48000


def say(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def capture(target, channels, positions, rate, name, passive=True):
    if not shutil.which("pw-record"):
        say({"error": "pw-record not found (pipewire-tools)"})
        sys.exit(2)
    # passive: follows the player without keeping anything awake; the console's mix
    # source may be suspended, so that capture is an ordinary one and wakes it up
    props = "{ node.name = %s node.description = \"angelOS lyrics level\" node.dont-reconnect = true%s%s }" % (
        name, " node.passive = true" if passive else "", " stream.dont-remix = true" if positions else "")
    cmd = ["pw-record", "--raw", "--target", str(target), "--channels", str(channels),
           "--format", "f32", "--rate", str(rate), "--latency", "40ms", "-P", props]
    if positions:
        cmd += ["--channel-map", ",".join(positions)]
    cmd.append("-")
    return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=0)


def db(x):
    return 20 * math.log10(x) if x > 1e-9 else FLOOR_DB


class Emitter:
    """Prints a value when it moved enough, not more often than `every` seconds."""

    def __init__(self, step=1.0, every=0.5):
        self.last = None
        self.at = 0.0
        self.step = step
        self.every = every

    def __call__(self, value, **extra):
        now = time.monotonic()
        if self.last is not None and (abs(value - self.last) < self.step or now - self.at < self.every):
            return
        self.last = value
        self.at = now
        say(dict({"db": round(value, 1)}, **extra))


class Ring:
    """The last few seconds of a mono capture, addressed by absolute sample index."""

    def __init__(self, seconds=4):
        self.buf = np.zeros(RATE * seconds, dtype=np.float32)
        self.end = 0                       # samples received so far
        self.lock = threading.Lock()
        self.alive = True

    def push(self, x):
        with self.lock:
            n = len(x)
            size = len(self.buf)
            if n >= size:
                self.buf[:] = x[-size:]
            else:
                self.buf = np.roll(self.buf, -n)
                self.buf[-n:] = x
            self.end += n

    def get(self, start, length):
        with self.lock:
            first = self.end - len(self.buf)
            # nothing from before the capture began: the zeros there read as a step
            if start < max(0, first) or start + length > self.end or length <= 0:
                return None
            i = start - first
            return self.buf[i:i + length].copy()


def pump(proc, ring, channels):
    frame = channels * 4 * 1200            # 25 ms
    pending = b""
    while True:
        chunk = proc.stdout.read(frame)
        if not chunk:
            break
        pending += chunk
        usable = len(pending) // (channels * 4) * channels * 4
        if usable:
            a = np.frombuffer(pending[:usable], dtype=np.float32).reshape(-1, channels)
            ring.push(a.sum(axis=1))
            pending = pending[usable:]
    ring.alive = False


def rode(player, mix, positions):
    if np is None:
        say({"error": "python-numpy is needed to read the RØDECaster fader"})
        sys.exit(2)
    pos = positions.split(",") if positions else None
    ref, out = Ring(8), Ring(8)
    p1 = capture(player, 2, None, RATE, "angelos-lyrics-music")
    p2 = capture(mix, 2, pos, RATE, "angelos-lyrics-mix", passive=False)
    for proc, ring in ((p1, ref), (p2, out)):
        threading.Thread(target=pump, args=(proc, ring, 2), daemon=True).start()
    emit = Emitter()
    # Loudness envelopes, not waveforms: the console's input and output run on their
    # own clocks (a few hundred ppm apart here), so the waveforms drift past each
    # other within a second; their 20 ms energies don't. mix = g²·music + the rest:
    # the slope of mix energy over music energy is g².
    block = RATE // 50                     # 20 ms
    span = 100                             # 2 s of blocks per estimate
    lspan = 200                            # 4 s to find the delay
    search = 50                            # the two captures may be ±1 s apart
    lag = None                             # in blocks: mix index − music index
    lag_at = 0.0
    gain = None
    recent = []                            # the last second of raw estimates

    def energies(x):
        n = len(x) // block * block
        return (x[:n].reshape(-1, block) ** 2).mean(axis=1)

    def find_lag():
        # an older stretch of music, so the mix has its full ±1 s around it
        end = (min(ref.end, out.end) - (search + 10) * block) // block * block
        music = ref.get(end - lspan * block, lspan * block)
        wide = out.get(end - (lspan + search) * block, (lspan + 2 * search) * block)
        if music is None or wide is None:
            return None, 0.0
        em, ew = energies(music), energies(wide)
        if em.std() < 0.08 * em.mean() or em.mean() < 1e-7:
            return None, 0.0
        a = (em - em.mean()) / em.std()
        best, best_k = 0.0, None
        for k in range(0, 2 * search + 1):
            seg = ew[k:k + lspan]
            sd = seg.std()
            if len(seg) < lspan or sd <= 0:
                continue
            r = float(np.dot(a, (seg - seg.mean()) / sd)) / lspan
            if r > best:
                best, best_k = r, k
        return (best_k - search if best_k is not None else None), best

    while ref.alive and out.alive:
        time.sleep(0.1)
        now = time.monotonic()
        if lag is None or now - lag_at > 5:
            k, r = find_lag()
            if k is not None or r == 0.0:
                lag_at = now
            if k is not None and r > 0.3:
                lag = k
            elif k is not None:
                lag = None
                # the music has a beat but it is nowhere in the mix: the fader is down
                gain = FLOOR_DB
                recent.clear()
                emit(gain, lag=None)
                continue
        if lag is None:
            continue
        # the newest stretch both sides have
        end = (min(ref.end, out.end - lag * block) - 2 * block) // block * block
        music = ref.get(end - span * block, span * block)
        back = out.get(end - span * block + lag * block, span * block)
        if music is None or back is None:
            continue
        em, eo = energies(music), energies(back)
        if em.mean() < 1e-7 or em[-25:].mean() < 1e-7:   # ≈ -70 dBFS: paused, hold
            continue
        if em.std() < 0.08 * em.mean():                  # a steady drone: hold
            continue
        cov = float(np.mean((em - em.mean()) * (eo - eo.mean())))
        slope = cov / float(em.var())
        value = 10 * math.log10(slope) if slope > 1e-9 else FLOOR_DB
        # one estimate swings by several dB with the music under a fader standing
        # still: the median of the last second, then eased
        recent.append(value)
        del recent[:-9]
        mid = sorted(recent)[len(recent) // 2]
        gain = mid if gain is None else gain + (mid - gain) * 0.3
        emit(gain, lag=lag)
    for p in (p1, p2):
        p.terminate()
    return "ended"


def multitrack_next_to(mix):
    """The console's multitrack source beside its main mix: (node name, channel positions)."""
    try:
        nodes = json.loads(subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=5).stdout or "[]")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return None, None
    props = [(o.get("info") or {}).get("props") or {} for o in nodes if o.get("type") == "PipeWire:Interface:Node"]
    me = next((p for p in props if mix in (p.get("node.name"), str(p.get("object.serial")))), None)
    if not me or me.get("device.id") is None:
        return None, None
    # the mix source may be the multitrack itself (its first pair picked)
    for p in [me] + [p for p in props if p is not me]:
        if p.get("device.id") != me.get("device.id") or p.get("media.class") != "Audio/Source":
            continue
        pos = [c.strip() for c in str(p.get("audio.position") or "").strip("[] ").split(",") if c.strip()]
        if len(pos) >= 4 and len(pos) == int(p.get("audio.channels") or 0):
            return p.get("node.name"), pos
    return None, None


class Blocks:
    """A many-channel capture in 20 ms blocks, the last few seconds, by absolute block
    index: each block's Gram matrix (all the least squares need) and the loudness of
    each channel pair summed to mono, as the player's ring has it."""

    def __init__(self, channels, block, seconds=8):
        self.n = 50 * seconds
        self.block = block
        self.pairs = [(c, c + 1) for c in range(0, channels - 1, 2)]
        self.gram = np.zeros((self.n, channels, channels))
        self.env = np.zeros((self.n, len(self.pairs)))
        self.end = 0
        self.lock = threading.Lock()
        self.alive = True

    def push(self, x):
        b = x.astype(np.float64)
        g = b.T @ b
        env = [(g[l, l] + g[r, r] + 2 * g[l, r]) / len(b) for l, r in self.pairs]
        with self.lock:
            i = self.end % self.n
            self.gram[i] = g
            self.env[i] = env
            self.end += 1

    def get(self, start, count):
        """(loudness of each pair per block, the summed Gram) or None outside the ring."""
        with self.lock:
            if count <= 0 or start < max(0, self.end - self.n) or start + count > self.end:
                return None
            idx = np.arange(start, start + count) % self.n
            return self.env[idx].copy(), self.gram[idx].sum(axis=0)


def pump_blocks(proc, blocks, channels):
    frame = channels * 4 * blocks.block
    pending = b""
    while True:
        chunk = proc.stdout.read(frame)
        if not chunk:
            break
        pending += chunk
        while len(pending) >= frame:
            blocks.push(np.frombuffer(pending[:frame], dtype=np.float32).reshape(-1, channels))
            pending = pending[frame:]
    blocks.alive = False


def rode_multitrack(player, source, positions, fixed=None):
    channels = len(positions)
    block = RATE // 50                     # 20 ms
    ref, mt = Ring(8), Blocks(channels, block)
    p1 = capture(player, 2, None, RATE, "angelos-lyrics-music")
    p2 = capture(source, channels, positions, RATE, "angelos-lyrics-mix", passive=False)
    threading.Thread(target=pump, args=(p1, ref, 2), daemon=True).start()
    threading.Thread(target=pump_blocks, args=(p2, mt, channels), daemon=True).start()
    emit = Emitter()
    mix = mt.pairs[0]                      # AUX0/1: the mix after the faders
    tracks = list(range(1, len(mt.pairs)))  # the faders' tracks, before them
    candidates = [fixed] if fixed else tracks  # where the player may be
    span = 100                             # 2 s of blocks for the track's level
    lspan = 200                            # 4 s to find the track and the delay
    search = 50                            # ±1 s between the two captures
    window = 25                            # 0.5 s of samples for the least squares
    floor = 10 ** (-70 / 10)               # a quieter track: its gain can't be read
    silent = 10 ** (-120 / 10)             # a quieter channel: left out (digital zero)
    track = lag = None                     # pair index; lag in blocks: mix − music
    found_at = 0.0
    level = None                           # the track's energy over the player's
    gain = None
    recent = []

    def energies(x):
        n = len(x) // block * block
        return (x[:n].reshape(-1, block) ** 2).mean(axis=1)

    def find_track():
        # which track's loudness follows the player's, and how late: the tracks come
        # before their faders, so the player's one matches even with the fader down
        end = min(ref.end // block, mt.end) - search - 10
        music = ref.get((end - lspan) * block, lspan * block)
        wide = mt.get(end - lspan - search, lspan + 2 * search)
        if music is None or wide is None:
            return None, None, 0.0
        em = energies(music)
        if em.std() < 0.08 * em.mean() or em.mean() < 1e-7:
            return None, None, 0.0
        a = (em - em.mean()) / em.std()
        best = (0.0, None, None)
        for t in candidates:
            w = np.lib.stride_tricks.sliding_window_view(wide[0][:, t], lspan)
            sd = w.std(axis=1)
            ok = sd > 0
            if not ok.any():
                continue
            r = np.where(ok, ((w - w.mean(axis=1, keepdims=True)) @ a) / (np.where(ok, sd, 1) * lspan), 0.0)
            k = int(np.argmax(r))
            if r[k] > best[0]:
                best = (float(r[k]), t, k - search)
        return best[1], best[2], best[0]

    def fader():
        # the mix = Σ g · track over the last half second, left and right apart; the
        # voice, the chat and the game are tracks too, so they don't lean on g
        got = mt.get(mt.end - window, window)
        if got is None:
            return None
        G = got[1]
        n = window * block
        gs = []
        for side in (0, 1):
            col, s = mt.pairs[track][side], mix[side]
            if G[col, col] < n * floor:
                gs.append(None)
                continue
            active = [mt.pairs[t][side] for t in tracks if G[mt.pairs[t][side], mt.pairs[t][side]] > n * silent]
            xtx, xty, yy = G[np.ix_(active, active)], G[active, s], G[s, s]
            g = np.linalg.pinv(xtx) @ xty
            rss = max(yy - 2 * g @ xty + g @ xtx @ g, 0.0)
            # something in the mix that no track carries: don't trust this window
            gs.append(float(g[active.index(col)]) if yy > 0 and rss < 0.01 * yy else None)
        (l, r), (gl, gr) = mt.pairs[track], gs
        if gl is None and gr is None:
            return None
        if gl is None or gr is None:
            return (gl if gr is None else gr) ** 2
        # the gain of the track's mono sum, as the player's ring sums it
        return max(0.0, (gl * gl * G[l, l] + gr * gr * G[r, r] + 2 * gl * gr * G[l, r])
                   / max(G[l, l] + G[r, r] + 2 * G[l, r], 1e-30))

    while ref.alive and mt.alive:
        time.sleep(0.1)
        now = time.monotonic()
        if track is None or now - found_at > 5:
            t, k, r = find_track()
            if t is not None or r == 0.0:
                found_at = now
            if t is not None and r > 0.3:
                if t != track:
                    level = gain = None
                    recent.clear()
                track, lag = t, k
            elif t is not None:
                # the music has a beat but no track carries it: it doesn't go through the console
                track = lag = level = None
                gain = FLOOR_DB
                recent.clear()
                emit(gain, lag=None, track=None)
                continue
        if track is None:
            continue
        g2 = fader()
        if g2 is None:                     # the track quiet (paused) or the mix unexplained: hold
            continue
        # the console's input level on that track over the player's own output: steady
        # until a volume in between moves (the track's sink in PipeWire, say). Plain
        # energies over 2 s: the envelopes' slope sagged by dB whenever the two clocks
        # put the blocks a fraction apart
        end = min(ref.end // block, mt.end - lag) - 2
        music = ref.get((end - span) * block, span * block)
        got = mt.get(end - span + lag, span)
        if music is not None and got is not None:
            em, et = energies(music).mean(), got[0][:, track].mean()
            if em >= 1e-7 and et > 1e-12:
                ratio = float(et / em)
                level = ratio if level is None else level + (ratio - level) * 0.3
        if level is None:
            continue
        value = 10 * math.log10(g2 * level) if g2 * level > 1e-9 else FLOOR_DB
        recent.append(value)
        del recent[:-5]
        mid = sorted(recent)[len(recent) // 2]
        gain = mid if gain is None else gain + (mid - gain) * 0.5
        emit(gain, lag=lag, track="/".join(positions[c] for c in mt.pairs[track]))
    for p in (p1, p2):
        p.terminate()
    return "ended"


def stream(target):
    rate = RATE if np is not None else 12000
    frame = rate // 20                     # 50 ms
    proc = capture(target, 2, None, rate, "angelos-lyrics-level")
    emit = Emitter()
    level = FLOOR_DB
    import array
    while True:
        raw = b""
        need = frame * 2 * 4
        while len(raw) < need:
            chunk = proc.stdout.read(need - len(raw))
            if not chunk:
                return proc.wait()
            raw += chunk
        if np is not None:
            a = np.frombuffer(raw, dtype=np.float32)
            rms = float(np.sqrt(np.mean(a * a)))
        else:
            a = array.array("f")
            a.frombytes(raw)
            rms = math.sqrt(sum(x * x for x in a) / max(1, len(a)))
        value = max(FLOOR_DB, db(rms))
        # fast attack, slow release: loud parts light up at once, quiet ones fade
        k = 0.6 if value > level else 0.08
        level = level + (value - level) * k
        emit(level)


def main():
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    signal.signal(signal.SIGTERM, lambda *_: os._exit(0))
    args = sys.argv[1:]
    if len(args) in (3, 4) and args[0] == "rode":
        source, positions = multitrack_next_to(args[2]) if np is not None else (None, None)
        fixed = None
        if source and len(args) == 4:
            # a pair picked by hand: the multitrack's own mix (its first pair), or the
            # player's track on it; any other source with a pair goes the old way
            pair = args[3].split(",")
            i = positions.index(pair[0]) if source == args[2] and pair[0] in positions else -1
            if i > 0 and i % 2 == 0 and positions[i + 1:i + 2] == pair[1:2]:
                fixed = i // 2
            elif i != 0 or positions[:2] != pair:
                source = None
        if source:
            code = rode_multitrack(args[1], source, positions, fixed)
        else:
            code = rode(args[1], args[2], args[3] if len(args) == 4 else "")
    elif len(args) == 2 and args[0] == "stream":
        code = stream(args[1])
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    say({"error": "capture ended (%s)" % code})
    sys.exit(2)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        os._exit(0)
