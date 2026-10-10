import QtQuick
import qs.config
import qs.services

// Flickable with a chunky pixel scrollbar.
Item {
    id: root

    property alias flick: flick
    property alias contentHeight: flick.contentHeight
    property alias contentY: flick.contentY
    property bool barVisible: flick.contentHeight > flick.height + 1
    default property alias content: flick.flickableData
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    // Mouse wheel: fixed steps with a short glide. Flickable's own wheel
    // handling is velocity based and crawls on long settings pages.
    function scrollBy(dy) {
        const max = Math.max(0, flick.contentHeight - flick.height);
        const from = glide.running ? glide.to : flick.contentY;
        const to = Math.max(0, Math.min(max, from + dy));
        glide.stop();
        if (to === flick.contentY)
            return;
        glide.from = flick.contentY;
        glide.to = to;
        glide.start();
    }
    NumberAnimation {
        id: glide
        target: flick
        property: "contentY"
        duration: 110
        easing.type: Easing.OutCubic
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.rightMargin: root.barVisible ? bar.width + (root.fluent ? 4 : Theme.u * 3) : 0
        clip: true
        contentWidth: width
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 4000
        maximumFlickVelocity: 3000
        pixelAligned: true

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: e => {
                if (flick.contentHeight <= flick.height)
                    return;
                const dy = e.pixelDelta.y !== 0 ? -e.pixelDelta.y : -e.angleDelta.y / 120 * Theme.u * 40;
                root.scrollBy(dy);
            }
        }
    }

    PxBox {
        id: bar
        visible: root.barVisible
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.fluent ? 6 : Theme.u * 8
        sunken: true
        color: Theme.sunken
        opacity: root.fluent ? 0.0 : 1
        fluentRadius: 3

        PxBox {
            id: handle
            x: 0
            width: parent.width - bar.inset * 2
            height: Math.max(Theme.u * 12, (parent.height - bar.inset * 2) * flick.visibleArea.heightRatio)
            y: (parent.height - bar.inset * 2 - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
            color: handleMouse.pressed ? Theme.accent : Theme.faceAlt

            MouseArea {
                id: handleMouse
                anchors.fill: parent
                property real startY
                property real startContent
                onPressed: m => {
                    startY = mapToItem(bar, 0, m.y).y;
                    startContent = flick.contentY;
                }
                onPositionChanged: m => {
                    if (!pressed)
                        return;
                    const dy = mapToItem(bar, 0, m.y).y - startY;
                    const range = bar.height - handle.height;
                    const maxY = flick.contentHeight - flick.height;
                    flick.contentY = Math.max(0, Math.min(maxY, startContent + dy / Math.max(1, range) * maxY));
                }
            }
        }
    }
    Rectangle {
        visible: root.fluent && root.barVisible
        anchors.right: parent.right
        width: handleArea.containsMouse || handleArea.pressed ? 6 : 3
        radius: width / 2
        height: Math.max(24, root.height * flick.visibleArea.heightRatio)
        y: (root.height - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
        color: WinStyle.text3
        Behavior on width {
            NumberAnimation {
                duration: WinStyle.fast
            }
        }
        MouseArea {
            id: handleArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            property real startY
            property real startContent
            onPressed: m => {
                startY = mapToItem(root, 0, m.y).y;
                startContent = flick.contentY;
            }
            onPositionChanged: m => {
                if (!pressed)
                    return;
                const dy = mapToItem(root, 0, m.y).y - startY;
                const range = root.height - parent.height;
                const maxY = flick.contentHeight - flick.height;
                flick.contentY = Math.max(0, Math.min(maxY, startContent + dy / Math.max(1, range) * maxY));
            }
        }
    }
}
