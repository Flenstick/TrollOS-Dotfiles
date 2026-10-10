pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// One thing on the overlay: a note, a picture/GIF or a video. The item itself is
// the content rectangle; while the overlay is open a title bar sits above it
// (drag, pin, clickable, sound/colour, delete) and a grip in the corner resizes.
// Closed, only pinned items stay, without chrome, and let clicks through unless
// "clickable" is on.
Item {
    id: root

    required property string modelData       // item id
    property bool active: false              // the overlay is open on this screen
    readonly property var d: {
        Overlay.revision;
        return Object.assign({}, Overlay.byId(modelData));
    }
    readonly property string kind: d.kind || "note"
    readonly property bool pinned: !!d.pinned
    readonly property bool clickableNow: !active && pinned && !!d.clickable
    readonly property int titleH: Theme.sizeBody + Theme.u * 9
    readonly property bool animated: kind === "image" && Overlay.isAnimated(d.path || "")
    readonly property var picture: animated ? gif : still
    readonly property real ratio: kind === "video" ? (video.item ? video.item.ratio : 0) : (picture.status === Image.Ready && picture.implicitHeight > 0 ? picture.implicitWidth / picture.implicitHeight : 0)
    readonly property var noteColor: ({
            "pink": ["#ffd1e6", "#3b2233"],
            "yellow": ["#fff1a8", "#3a3220"],
            "mint": ["#c6f4d6", "#1f3a2a"],
            "blue": ["#cfe2ff", "#1f2a3d"],
            "lilac": ["#e3d3ff", "#2e2340"]
        })[d.color] || [Theme.face, Theme.text]
    property bool paused: false
    property bool ready: false               // geometry restored from the store
    readonly property url mediaUrl: d.path ? "file://" + d.path : ""

    visible: active || pinned
    z: barMouse.drag.active || bodyDrag.drag.active || grip.pressed ? 10 : 1

    Component.onCompleted: {
        x = d.x;
        y = d.y;
        width = Math.max(Theme.u * 40, d.w || 260);
        height = Math.max(Theme.u * 30, d.h || 200);
        clampIn();
        ready = true;
        if (ratio > 0 && d.fit)
            fitTimer.restart();
    }
    function clampIn() {
        if (!parent || parent.width <= 0 || parent.height <= 0)
            return;
        x = Math.round(Math.max(0, Math.min(x, parent.width - width)));
        y = Math.round(Math.max(titleH, Math.min(y, parent.height - height)));
    }
    Connections {
        target: root.parent
        function onWidthChanged() {
            root.clampIn();
        }
        function onHeightChanged() {
            root.clampIn();
        }
    }
    function save() {
        if (!ready || width <= 0 || height <= 0)
            return;
        Overlay.patch(modelData, {
            "x": Math.round(x),
            "y": Math.round(y),
            "w": Math.round(width),
            "h": Math.round(height)
        });
    }
    // first load of a picture/video: frame follows its proportions
    onRatioChanged: if (ratio > 0 && d.fit)
        fitTimer.restart()
    Timer {
        id: fitTimer
        interval: 30
        onTriggered: root.fitToRatio()
    }
    function fitToRatio() {
        if (!(ratio > 0 && d.fit))
            return;
        if (!ready || !parent || parent.width <= 0) {
            fitTimer.restart();
            return;
        }
        const maxW = parent ? parent.width * 0.4 : 600;
        const maxH = parent ? parent.height * 0.45 : 450;
        let w = Math.min(maxW, Math.max(width, 320));
        let h = w / ratio;
        if (h > maxH) {
            h = maxH;
            w = h * ratio;
        }
        width = Math.round(w);
        height = Math.round(h);
        clampIn();
        Overlay.patch(modelData, {
            "fit": false
        });
        save();
    }

    // ---- content ----
    Item {
        id: content
        anchors.fill: parent
        opacity: root.d.opacity === undefined ? 1 : root.d.opacity

        // note
        PxBox {
            visible: root.kind === "note"
            anchors.fill: parent
            color: root.noteColor[0]
            shadow: Config.appearance.shadows

            MouseArea {
                anchors.fill: parent
                enabled: root.active || root.clickableNow
                cursorShape: Qt.IBeamCursor
                onPressed: {
                    editor.forceActiveFocus();
                    editor.cursorPosition = editor.text.length;
                }
                // Ctrl+wheel — text size
                onWheel: w => {
                    if (!(w.modifiers & Qt.ControlModifier)) {
                        w.accepted = false;
                        return;
                    }
                    const cur = root.d.fontSize || Theme.sizeBody;
                    Overlay.patch(root.modelData, {
                        "fontSize": Math.max(9, Math.min(72, cur + (w.angleDelta.y > 0 ? 2 : -2)))
                    });
                }
            }
            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: Theme.u * 6
                clip: true
                contentWidth: width
                contentHeight: Math.max(height, editor.contentHeight)
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                TextEdit {
                    id: editor
                    width: flick.width
                    height: Math.max(flick.height, contentHeight)
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    readOnly: !(root.active || root.clickableNow)
                    activeFocusOnPress: !readOnly
                    selectByMouse: !readOnly
                    color: root.noteColor[1]
                    selectionColor: Theme.select
                    selectedTextColor: Theme.selectText
                    font.family: Theme.fontBody
                    font.pixelSize: root.d.fontSize || Theme.sizeBody
                    renderType: Text.NativeRendering
                    Component.onCompleted: text = root.d.text || ""
                    onTextChanged: if (text !== (root.d.text || ""))
                        Overlay.patch(root.modelData, {
                            "text": text
                        })
                    Keys.onEscapePressed: e => {
                        if (root.active)
                            Overlay.open = false;
                        else
                            editor.focus = false;
                    }
                    onCursorRectangleChanged: {
                        if (cursorRectangle.y < flick.contentY)
                            flick.contentY = cursorRectangle.y;
                        else if (cursorRectangle.y + cursorRectangle.height > flick.contentY + flick.height)
                            flick.contentY = cursorRectangle.y + cursorRectangle.height - flick.height;
                    }
                }
                PxText {
                    visible: editor.text === "" && root.active
                    width: parent.width
                    text: I18n.t("пиши тут… ♡", "write here… ♡")
                    color: Qt.alpha(root.noteColor[1], 0.5)
                    font.pixelSize: editor.font.pixelSize
                    wrapMode: Text.Wrap
                }
            }
        }

        // picture / GIF
        Image {
            id: still
            visible: root.kind === "image" && !root.animated
            anchors.fill: parent
            // an item's file never changes: set once (a binding loops while GIFs load)
            Component.onCompleted: if (root.kind === "image" && !root.animated)
                source = root.mediaUrl
            sourceSize: Qt.size(2560, 2560)   // fits inside, keeps proportions
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
        }
        AnimatedImage {
            id: gif
            visible: root.animated
            anchors.fill: parent
            Component.onCompleted: if (root.animated)
                source = root.mediaUrl
            fillMode: Image.PreserveAspectFit
            cache: false
            smooth: true
            playing: visible && !root.paused
        }

        Loader {
            id: video
            anchors.fill: parent
            active: root.kind === "video" && root.visible
            asynchronous: true
            onLoaded: item.paused = Qt.binding(() => root.paused)
            Component.onCompleted: setSource(Qt.resolvedUrl("OverlayVideo.qml"), {
                "path": Qt.binding(() => root.d.path || ""),
                "muted": Qt.binding(() => root.d.muted !== false)
            })
        }

        PxText {
            anchors.centerIn: parent
            width: parent.width - Theme.u * 8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: root.kind === "image" && root.picture.status === Image.Error || root.kind === "video" && (video.status === Loader.Error || video.item && video.item.failed)
            text: I18n.t("не открывается: ", "can't open: ") + (root.d.name || "")
            color: Theme.danger
        }

        // media: drag by the body while open, click pauses (also when pinned + clickable)
        MouseArea {
            id: bodyDrag
            visible: root.kind !== "note"
            anchors.fill: parent
            enabled: root.active || root.clickableNow
            cursorShape: root.active ? (drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
            drag.target: root.active ? root : null
            drag.threshold: Theme.u * 3
            drag.minimumX: 0
            drag.minimumY: root.titleH
            drag.maximumX: root.parent ? root.parent.width - root.width : 0
            drag.maximumY: root.parent ? root.parent.height - root.height : 0
            property bool moved: false
            onPressed: moved = false
            onPositionChanged: if (drag.active)
                moved = true
            onReleased: moved ? root.save() : (root.paused = !root.paused)
        }

        // paused badge
        PxBox {
            visible: root.paused && root.kind !== "note"
            anchors.centerIn: parent
            width: Theme.u * 18
            height: width
            color: Qt.alpha(Theme.face, 0.85)
            PxIcon {
                anchors.centerIn: parent
                name: "play"
            }
        }
    }

    // ---- chrome (open overlay only) ----
    Rectangle {
        visible: root.active
        anchors.fill: parent
        anchors.margins: -Theme.u
        color: "transparent"
        border.width: Theme.u
        border.color: root.pinned ? Theme.accent : Theme.edge
        z: -1
    }

    Item {
        id: bar
        visible: root.active
        y: -root.titleH - Theme.u
        x: -Theme.u
        width: root.width + Theme.u * 2
        height: root.titleH

        PxBox {
            anchors.fill: parent
            color: root.pinned ? Theme.mix(Theme.menuHeader, Theme.accent, 0.35) : Theme.menuHeader
        }

        MouseArea {
            id: barMouse
            anchors.fill: parent
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: root
            drag.threshold: 1
            drag.minimumX: 0
            drag.minimumY: root.titleH
            drag.maximumX: root.parent ? root.parent.width - root.width : 0
            drag.maximumY: root.parent ? root.parent.height - root.height : 0
            onReleased: root.save()
            // wheel — opacity of the content
            onWheel: w => {
                const cur = root.d.opacity === undefined ? 1 : root.d.opacity;
                Overlay.patch(root.modelData, {
                    "opacity": Math.round(Math.max(0.15, Math.min(1, cur + (w.angleDelta.y > 0 ? 0.05 : -0.05))) * 100) / 100
                });
            }
        }

        Row {
            id: titleRow
            anchors.left: parent.left
            anchors.leftMargin: Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.kind === "note" ? "document" : root.kind === "video" ? "play" : "image"
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, bar.width - buttons.width - Theme.u * 18)
                elide: Text.ElideMiddle
                text: {
                    const op = root.d.opacity !== undefined && root.d.opacity < 1 ? "  " + Math.round(root.d.opacity * 100) + "%" : "";
                    return (root.kind === "note" ? I18n.t("заметка.txt", "note.txt") : (root.d.name || "media")) + op;
                }
            }
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u

            BarButton {
                visible: root.kind === "note"
                icon: "palette"
                tip: I18n.t("цвет", "colour")
                onClicked: {
                    const list = Overlay.noteColors;
                    Overlay.patch(root.modelData, {
                        "color": list[(list.indexOf(root.d.color) + 1) % list.length]
                    });
                }
            }
            BarButton {
                visible: root.kind === "video"
                icon: root.d.muted !== false ? "speakerMute" : "speaker"
                tip: I18n.t("звук", "sound")
                onClicked: Overlay.patch(root.modelData, {
                    "muted": root.d.muted === false
                })
            }
            BarButton {
                visible: root.pinned
                icon: "mouse"
                on: !!root.d.clickable
                tip: root.d.clickable ? I18n.t("кликабельно, когда закреплено", "clickable when pinned") : I18n.t("клики проходят насквозь", "clicks pass through")
                onClicked: Overlay.patch(root.modelData, {
                    "clickable": !root.d.clickable
                })
            }
            BarButton {
                icon: "pin"
                on: root.pinned
                tip: root.pinned ? I18n.t("закреплено: остаётся на экране", "pinned: stays on screen") : I18n.t("закрепить на экране", "pin to screen")
                onClicked: Overlay.patch(root.modelData, {
                    "pinned": !root.pinned
                })
            }
            BarButton {
                icon: "close"
                danger: true
                tip: I18n.t("удалить", "delete")
                onClicked: Overlay.remove(root.modelData)
            }
        }

        // tooltip of the hovered button
        PxBox {
            id: tipBox
            property string text: ""
            visible: text !== ""
            anchors.right: parent.right
            y: -height - Theme.u
            width: tipText.implicitWidth + Theme.u * 8
            height: tipText.implicitHeight + Theme.u * 4
            color: Theme.face
            PxText {
                id: tipText
                anchors.centerIn: parent
                text: tipBox.text
                kind: "tiny"
            }
        }
    }

    // resize grip (media keep their proportions)
    Item {
        visible: root.active
        width: Theme.u * 9
        height: width
        x: root.width - width + Theme.u * 2
        y: root.height - height + Theme.u * 2
        PxBox {
            anchors.fill: parent
            color: grip.containsMouse || grip.pressed ? Theme.accent : Theme.face
        }
        PxIcon {
            anchors.centerIn: parent
            bitmap: ["....#", "...##", "..#.#", ".#..#", "#####"]
        }
        MouseArea {
            id: grip
            anchors.fill: parent
            anchors.margins: -Theme.u * 2
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            property point start
            property size base
            onPressed: m => {
                start = mapToItem(root.parent, m.x, m.y);
                base = Qt.size(root.width, root.height);
            }
            onPositionChanged: m => {
                if (!pressed)
                    return;
                const p = mapToItem(root.parent, m.x, m.y);
                const minW = Theme.u * 40, minH = Theme.u * 24;
                let w = Math.max(minW, Math.min(base.width + p.x - start.x, root.parent.width - root.x));
                let h = Math.max(minH, Math.min(base.height + p.y - start.y, root.parent.height - root.y));
                if (root.kind !== "note" && root.ratio > 0 && !(m.modifiers & Qt.ShiftModifier)) {
                    h = w / root.ratio;
                    if (root.y + h > root.parent.height) {
                        h = root.parent.height - root.y;
                        w = h * root.ratio;
                    }
                }
                root.width = Math.round(w);
                root.height = Math.round(h);
            }
            onReleased: root.save()
        }
    }

    component BarButton: Item {
        id: bb
        property string icon: ""
        property string tip: ""
        property bool on: false
        property bool danger: false
        signal clicked
        width: root.titleH - Theme.u * 3
        height: width
        PxBox {
            anchors.fill: parent
            sunken: bbMouse.pressed || bb.on
            color: bb.danger && bbMouse.containsMouse ? Theme.danger : bb.on ? Theme.mix(Theme.face, Theme.accent, Theme.dark ? 0.45 : 0.35) : bbMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : Theme.face
        }
        PxIcon {
            anchors.centerIn: parent
            name: bb.icon
            ink: bb.danger && bbMouse.containsMouse ? "#ffffff" : (Theme.dark ? Theme.text : Theme.edge)
        }
        MouseArea {
            id: bbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bb.clicked()
            onContainsMouseChanged: tipBox.text = containsMouse ? bb.tip : (tipBox.text === bb.tip ? "" : tipBox.text)
        }
    }
}
