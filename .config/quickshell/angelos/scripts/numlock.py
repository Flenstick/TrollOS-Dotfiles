#!/usr/bin/env python3
"""NumLock on login, for real (Settings → Keyboard → NumLock on login).

niri's `numlock` (cfg/input.kdl) only acts when niri itself starts, and not
every build or keymap honours it (angelOS issue #12). This checks the keyboards'
NumLock LEDs and, when it is off, taps NumLock once through a short-lived
virtual keyboard (uinput) — the compositor then turns it on for every keyboard.

  numlock.py status    -> on | off | unknown   (no LED to read)
  numlock.py ensure    -> on (already) | tapped | unknown | noperm

No key is read or logged; the only key ever sent is NumLock.
"""
import fcntl
import glob
import os
import struct
import sys
import time

EV_SYN, EV_KEY, SYN_REPORT, KEY_NUMLOCK = 0, 1, 0, 69
UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565
UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502
BUS_VIRTUAL = 0x06


def status():
    leds = glob.glob("/sys/class/leds/*::numlock/brightness")
    if not leds:
        return "unknown"
    states = []
    for led in leds:
        try:
            states.append(int(open(led).read().strip() or 0) > 0)
        except (OSError, ValueError):
            pass
    if not states:
        return "unknown"
    return "on" if any(states) else "off"


def event(fd, kind, code, value):
    now = time.time()
    os.write(fd, struct.pack("llHHi", int(now), int((now % 1) * 1e6), kind, code, value))


def tap():
    fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
    try:
        fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
        fcntl.ioctl(fd, UI_SET_KEYBIT, KEY_NUMLOCK)
        # the legacy uinput_user_dev: name[80], input_id, ff_effects_max, abs arrays
        name = b"angelOS numlock".ljust(80, b"\0")
        dev = name + struct.pack("HHHH", BUS_VIRTUAL, 0x1d6b, 0x0104, 1) + struct.pack("i", 0) + b"\0" * (4 * 64 * 4)
        os.write(fd, dev)
        fcntl.ioctl(fd, UI_DEV_CREATE)
        time.sleep(0.4)                     # the compositor picks the new keyboard up
        for value in (1, 0):
            event(fd, EV_KEY, KEY_NUMLOCK, value)
            event(fd, EV_SYN, SYN_REPORT, 0)
            time.sleep(0.03)
        time.sleep(0.2)
        fcntl.ioctl(fd, UI_DEV_DESTROY)
    finally:
        os.close(fd)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    now = status()
    if cmd == "status":
        print(now)
        return 0
    if cmd != "ensure":
        print(__doc__, file=sys.stderr)
        return 2
    if now != "off":
        print(now)
        return 0
    try:
        tap()
    except PermissionError:
        print("noperm")
        return 1
    except OSError as error:
        print("error: " + str(error))
        return 1
    print("tapped")
    return 0


if __name__ == "__main__":
    sys.exit(main())
