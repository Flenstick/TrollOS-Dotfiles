#!/usr/bin/env python3
"""Hand a click on to what is under the pointer — for the shake-to-find overlay
(services/CursorShake, modules/cursor/ShakeCursor).

  vpointer.py     reads commands on stdin, one a line:
                    click BUTTON   a press and a release (Linux codes: 272 left, 273 right,
                                   274 middle, 275 side, 276 extra)
                    wheel DY DX    wheel notches (+ = down / right), fractions for touchpads
                  prints "ready" once the compositor's virtual pointer is there, "none"
                  (and exits) when it isn't.

While the big arrow is up, the overlay holds the pointer: only the surface under the pointer
can hide the real arrow, and only it learns where the pointer is (niri tells nobody). A click
that lands on the overlay ends the effect, the overlay goes, and this gives the same click to
whatever is under the pointer now — through wlr-virtual-pointer-unstable-v1 (niri has it), at
the pointer's own position: nothing is moved. Only what the overlay caught is ever sent.
Pure Python, like gamma.py: the wire protocol is small enough to speak directly.
"""
import os
import select
import socket
import struct
import sys
import time

BUTTONS = {272, 273, 274, 275, 276}


class Wayland:
    def __init__(self):
        name = os.environ.get("WAYLAND_DISPLAY", "wayland-0")
        path = name if name.startswith("/") else os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), name)
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(path)
        self.next_id = 2
        self.inbox = b""
        self.globals = {}
        self.registry = self.new_id()
        self.send(1, 1, struct.pack("=I", self.registry))      # wl_display.get_registry
        self.done = None

    def new_id(self):
        i = self.next_id
        self.next_id += 1
        return i

    @staticmethod
    def string(s):
        b = s.encode() + b"\0"
        return struct.pack("=I", len(b)) + b + b"\0" * (-len(b) % 4)

    def send(self, obj, opcode, payload=b""):
        self.sock.sendall(struct.pack("=II", obj, ((8 + len(payload)) << 16) | opcode) + payload)

    def read(self):
        data = self.sock.recv(65536)
        if not data:
            raise SystemExit("compositor gone")
        self.inbox += data
        while len(self.inbox) >= 8:
            obj, word = struct.unpack_from("=II", self.inbox)
            size, opcode = word >> 16, word & 0xFFFF
            if len(self.inbox) < size:
                break
            body, self.inbox = self.inbox[8:size], self.inbox[size:]
            if obj == 1 and opcode == 0:                         # wl_display.error
                raise SystemExit("wayland error")
            if obj == self.registry and opcode == 0:            # wl_registry.global
                name, n = struct.unpack_from("=II", body)
                iface = body[8:8 + n - 1].decode()
                version = struct.unpack_from("=I", body, 8 + n + (-n % 4))[0]
                self.globals[iface] = (name, version)
            if obj == self.done:                                 # wl_callback.done
                self.done = None

    def roundtrip(self):
        self.done = self.new_id()
        self.send(1, 0, struct.pack("=I", self.done))           # wl_display.sync
        while self.done is not None:
            self.read()


def now():
    return int(time.monotonic() * 1000) & 0xFFFFFFFF


def fixed(v):
    return int(round(v * 256))


def main():
    try:
        wl = Wayland()
        wl.roundtrip()
    except OSError:
        print("none", flush=True)
        return 1
    if "zwlr_virtual_pointer_manager_v1" not in wl.globals:
        print("none", flush=True)
        return 1
    name, _ = wl.globals["zwlr_virtual_pointer_manager_v1"]
    manager = wl.new_id()
    wl.send(wl.registry, 0, struct.pack("=I", name) + wl.string("zwlr_virtual_pointer_manager_v1") + struct.pack("=II", 1, manager))
    ptr = wl.new_id()
    wl.send(manager, 0, struct.pack("=II", 0, ptr))              # create_virtual_pointer(seat: null)
    wl.roundtrip()
    print("ready", flush=True)

    def frame():
        wl.send(ptr, 4)

    def settle():
        # a motion of nothing: the compositor looks again at what is under the pointer
        # (the overlay has just gone), so the click lands there
        wl.send(ptr, 0, struct.pack("=Iii", now(), 0, 0))
        frame()
        wl.roundtrip()
        time.sleep(0.012)

    buf = b""
    while True:
        ready, _, _ = select.select([sys.stdin.buffer, wl.sock], [], [])
        if wl.sock in ready:
            wl.read()
        if sys.stdin.buffer not in ready:
            continue
        chunk = os.read(sys.stdin.fileno(), 4096)
        if not chunk:
            return 0
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            words = line.decode(errors="ignore").split()
            try:
                if words[:1] == ["click"] and int(words[1]) in BUTTONS:
                    settle()
                    wl.send(ptr, 2, struct.pack("=III", now(), int(words[1]), 1))
                    frame()
                    wl.roundtrip()
                    time.sleep(0.01)
                    wl.send(ptr, 2, struct.pack("=III", now(), int(words[1]), 0))
                    frame()
                    wl.roundtrip()
                elif words[:1] == ["wheel"] and len(words) == 3:
                    settle()
                    for axis, notches in ((0, float(words[1])), (1, float(words[2]))):
                        if not notches:
                            continue
                        wl.send(ptr, 5, struct.pack("=I", 0))    # axis_source: wheel
                        whole = int(notches)
                        if whole == notches:
                            wl.send(ptr, 7, struct.pack("=IIii", now(), axis, fixed(15 * notches), whole))
                        else:
                            wl.send(ptr, 3, struct.pack("=IIi", now(), axis, fixed(15 * notches)))
                        frame()
                    wl.roundtrip()
            except (ValueError, IndexError):
                continue


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
