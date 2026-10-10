import QtQuick
import QtQuick.Window
import QtTest

// Minimal reproducer for the Qt Quick crash angelOS works around with
// widgets/RightClickGuard.qml (see docs/QTBUG-right-click-origin.md).
//
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tst_rightclick_origin.qml
//
// Qt 6.11.2: a right click at exactly (0,0) of a window that has no active
// focus item (it does not take focus: layer-shell panels, tool windows), which
// no item accepts, crashes in QQuickDeliveryAgentPrivate::contextMenuTargets()
// → QQuickItem::mapToScene() on a null item (SIGSEGV, exit 139). One pixel
// further, or with an item that accepts the right button there, all is fine.
TestCase {
    name: "RightClickAtWindowOrigin"
    when: windowShown

    Window {
        id: panel
        width: 200
        height: 150
        visible: true
        flags: Qt.WindowDoesNotAcceptFocus
        Rectangle {
            anchors.fill: parent
            color: "pink"
        }
    }

    function test_rightClickNextToOrigin() {
        tryVerify(() => panel.visible);
        mouseClick(panel.contentItem, 1, 1, Qt.RightButton);
        verify(true);
    }
    function test_rightClickAtOrigin() {
        tryVerify(() => panel.visible);
        compare(panel.activeFocusItem, null);
        mouseClick(panel.contentItem, 0, 0, Qt.RightButton);
        // not reached on an affected Qt: the runner dies with SIGSEGV
        verify(true);
    }
}
