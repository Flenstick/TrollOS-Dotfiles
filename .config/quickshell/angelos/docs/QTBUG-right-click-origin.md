# Qt bug report draft: right click at a window's (0,0) crashes Qt Quick

angelOS works around this with `widgets/RightClickGuard.qml` (a 1×1 MouseArea
that accepts the right button in every window). Once Qt ships a fix, the guard
and the "every window has a RightClickGuard" check in `scripts/test-ui.sh` can go.

Submit at <https://bugreports.qt.io> → Create → Project **Qt**, Component
**Quick: Core Declarative QML** (or *Quick: Input*), with the text below and
`tests/qt/tst_rightclick_origin.qml` attached.

---

**Summary:** SIGSEGV in QQuickDeliveryAgentPrivate::contextMenuTargets() on a
right click at window position (0,0) when no item accepts it and no item has
active focus

**Affects version:** 6.11.2 (Arch Linux / CachyOS, Wayland and offscreen QPA)

**Description**

A right mouse button press/release that lands exactly on pixel (0,0) of a
QQuickWindow crashes the application when

* no item in the scene accepts the right button, and
* the window has no active focus item (`activeFocusItem === null`, e.g. a
  window with `Qt.WindowDoesNotAcceptFocus`, or a Wayland layer-shell panel
  without keyboard focus).

The crash is inside the context-menu event path added in 6.9/6.10:
`QQuickDeliveryAgentPrivate::contextMenuTargets()` takes the
`activeFocusItem` and calls `mapToScene()` on it — for a click at (0,0) the
code path that falls back to the focus item is taken, `activeFocusItem` is
`nullptr`, and the call dereferences it. A click one pixel away, or any item
accepting `Qt.RightButton`, avoids it.

In practice this hits desktop shells built on Qt Quick (Quickshell): a context
menu opens with its corner under the pointer, the user right-clicks again at the
same spot, and the whole shell goes down.

**Steps to reproduce**

1. Save the attached `tst_rightclick_origin.qml`.
2. `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tst_rightclick_origin.qml`

**Expected:** both test functions pass.
**Actual:** `test_rightClickNextToOrigin` passes, `test_rightClickAtOrigin`
crashes (exit 139). Checked with Qt 6.11.2, offscreen QPA; the same stack on
Wayland:

```
#1  QQuickItem::mapToScene(QPointF const&) const                                  libQt6Quick.so.6
#2  QQuickDeliveryAgentPrivate::contextMenuTargets(QQuickItem*, QContextMenuEvent const*) const
#3  QQuickDeliveryAgentPrivate::deliverContextMenuEvent(QContextMenuEvent*)
#4  QQuickDeliveryAgent::event(QEvent*)
#5  QQuickWindow::event(QEvent*)
#6  QApplicationPrivate::notify_helper(QObject*, QEvent*)
#7  QCoreApplication::notifyInternal2(QObject*, QEvent*)
#8  QWindowPrivate::maybeSynthesizeContextMenuEvent(QMouseEvent*)                  libQt6Gui.so.6
#9  QQuickWindow::event(QEvent*)
#12 QGuiApplicationPrivate::processMouseEvent(QWindowSystemInterfacePrivate::MouseEvent*)
```
(from a real crash on Wayland, Qt 6.11.2; frame #0 is in libc)

**Workaround:** an item that accepts the right button at the window's origin
(e.g. `MouseArea { width: 1; height: 1; acceptedButtons: Qt.RightButton }`).
