#!/usr/bin/env python3
"""Служба прогресса задач KDE (org.kde.kuiserver / JobViewServerV2) для острова.

KDE-программы (KDE Connect, KIO) без Plasma показывают прогресс отдельным
окном. Если эта служба занята, они шлют прогресс сюда, а мы печатаем его
JSON-строками в stdout — остров angelOS их читает. В stdin можно написать
«cancel <id>», чтобы отменить задачу.
"""
import json
import warnings
import sys

import gi

warnings.filterwarnings("ignore", category=DeprecationWarning)
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

SERVER_XML = """
<node>
  <interface name="org.kde.JobViewServerV2">
    <method name="requestView">
      <arg name="desktopEntry" type="s" direction="in"/>
      <arg name="capabilities" type="i" direction="in"/>
      <arg name="hints" type="a{sv}" direction="in"/>
      <arg name="jobViewPath" type="o" direction="out"/>
    </method>
    <property name="requiresJobTracker" type="b" access="read"/>
    <signal name="requiresJobTrackerChanged">
      <arg name="requiresJobTracker" type="b"/>
    </signal>
  </interface>
  <interface name="org.kde.JobViewServer">
    <method name="requestView">
      <arg name="appName" type="s" direction="in"/>
      <arg name="appIconName" type="s" direction="in"/>
      <arg name="capabilities" type="i" direction="in"/>
      <arg name="trackerPath" type="o" direction="out"/>
    </method>
  </interface>
</node>
"""

JOB_XML = """
<node>
  <interface name="org.kde.JobViewV3">
    <method name="terminate">
      <arg name="errorCode" type="u" direction="in"/>
      <arg name="errorMessage" type="s" direction="in"/>
      <arg name="hints" type="a{sv}" direction="in"/>
    </method>
    <method name="update">
      <arg name="data" type="a{sv}" direction="in"/>
    </method>
    <signal name="suspendRequested"/>
    <signal name="resumeRequested"/>
    <signal name="cancelRequested"/>
    <signal name="updateRequested"/>
  </interface>
  <interface name="org.kde.JobViewV2">
    <method name="terminate"><arg name="errorMessage" type="s" direction="in"/></method>
    <method name="setSuspended"><arg name="suspended" type="b" direction="in"/></method>
    <method name="setTotalAmount"><arg name="amount" type="t" direction="in"/><arg name="unit" type="s" direction="in"/></method>
    <method name="setProcessedAmount"><arg name="amount" type="t" direction="in"/><arg name="unit" type="s" direction="in"/></method>
    <method name="setPercent"><arg name="percent" type="u" direction="in"/></method>
    <method name="setSpeed"><arg name="bytesPerSecond" type="t" direction="in"/></method>
    <method name="setElapsedTime"><arg name="elapsedTime" type="t" direction="in"/></method>
    <method name="setInfoMessage"><arg name="message" type="s" direction="in"/></method>
    <method name="setDescriptionField">
      <arg name="number" type="u" direction="in"/><arg name="name" type="s" direction="in"/>
      <arg name="value" type="s" direction="in"/><arg name="res" type="b" direction="out"/>
    </method>
    <method name="clearDescriptionField"><arg name="number" type="u" direction="in"/></method>
    <method name="setDestUrl"><arg name="destUrl" type="v" direction="in"/></method>
    <signal name="suspendRequested"/>
    <signal name="resumeRequested"/>
    <signal name="cancelRequested"/>
  </interface>
</node>
"""

server_info = Gio.DBusNodeInfo.new_for_xml(SERVER_XML)
job_info = Gio.DBusNodeInfo.new_for_xml(JOB_XML)
conn = None
jobs = {}  # id -> {"regs": [...], "path": str}
next_id = 1


def emit(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def plain(v):
    """GLib.Variant / python value -> JSON-friendly value."""
    if isinstance(v, GLib.Variant):
        v = v.unpack()
    if isinstance(v, (list, tuple)):
        return [plain(x) for x in v]
    if isinstance(v, dict):
        return {str(k): plain(x) for k, x in v.items()}
    if isinstance(v, (str, int, float, bool)) or v is None:
        return v
    return str(v)


def end_job(jid, code, msg):
    job = jobs.pop(jid, None)
    if not job:
        return
    emit({"ev": "end", "id": jid, "code": int(code), "msg": msg})
    # отрегистрируем чуть позже: клиент может ещё дослать вызовы
    def drop():
        for r in job["regs"]:
            conn.unregister_object(r)
        return False
    GLib.timeout_add(2000, drop)


def job_call(_c, _sender, path, iface, method, params, invocation):
    jid = int(path.rsplit("_", 1)[1])
    a = params.unpack()
    if method == "update":
        emit({"ev": "update", "id": jid, "data": plain(a[0])})
    elif method == "terminate":
        if iface == "org.kde.JobViewV3":
            end_job(jid, a[0], a[1])
        else:
            end_job(jid, 1 if a[0] else 0, a[0])
    elif method == "setPercent":
        emit({"ev": "update", "id": jid, "data": {"percent": a[0]}})
    elif method in ("setTotalAmount", "setProcessedAmount"):
        key = ("total" if method == "setTotalAmount" else "processed") + a[1].capitalize()
        emit({"ev": "update", "id": jid, "data": {key: a[0]}})
    elif method == "setSpeed":
        emit({"ev": "update", "id": jid, "data": {"speed": a[0]}})
    elif method == "setInfoMessage":
        emit({"ev": "update", "id": jid, "data": {"infoMessage": a[0]}})
    elif method == "setDescriptionField":
        n = a[0] + 1
        emit({"ev": "update", "id": jid, "data": {"descriptionLabel%d" % n: a[1], "descriptionValue%d" % n: a[2]}})
        invocation.return_value(GLib.Variant("(b)", (True,)))
        return
    invocation.return_value(None)


def new_job(app, caps, hints):
    global next_id
    jid = next_id
    next_id += 1
    path = "/JobViewServer/JobView_%d" % jid
    regs = [conn.register_object(path, i, job_call, None, None) for i in job_info.interfaces]
    jobs[jid] = {"regs": regs, "path": path}
    emit({"ev": "new", "id": jid, "app": app, "caps": caps, "hints": plain(hints)})
    return path


def server_call(_c, _sender, _path, iface, method, params, invocation):
    a = params.unpack()
    if iface == "org.kde.JobViewServerV2":
        path = new_job(a[0], a[1], a[2])
    else:
        path = new_job(a[0], a[2], {"appIconName": a[1]})
    invocation.return_value(GLib.Variant("(o)", (path,)))


def server_prop(_c, _sender, _path, _iface, name):
    if name == "requiresJobTracker":
        return GLib.Variant("b", False)
    return None


def on_bus(c, _name):
    global conn
    conn = c
    for i in server_info.interfaces:
        c.register_object("/JobViewServer", i, server_call, server_prop, None)


def on_name(_c, name):
    emit({"ev": "ready", "name": name})


def on_lost(_c, name):
    emit({"ev": "lost", "name": name})
    loop.quit()


def on_stdin(src, _cond):
    line = src.readline()
    if not line:
        loop.quit()
        return False
    parts = line.split()
    if len(parts) == 2 and parts[0] == "cancel" and parts[1].isdigit():
        job = jobs.get(int(parts[1]))
        if job:
            conn.emit_signal(None, job["path"], "org.kde.JobViewV3", "cancelRequested", None)
            conn.emit_signal(None, job["path"], "org.kde.JobViewV2", "cancelRequested", None)
    return True


loop = GLib.MainLoop()
Gio.bus_own_name(Gio.BusType.SESSION, "org.kde.kuiserver", Gio.BusNameOwnerFlags.DO_NOT_QUEUE, on_bus, on_name, on_lost)
GLib.io_add_watch(GLib.IOChannel.unix_new(sys.stdin.fileno()), GLib.IO_IN | GLib.IO_HUP, on_stdin)
loop.run()
