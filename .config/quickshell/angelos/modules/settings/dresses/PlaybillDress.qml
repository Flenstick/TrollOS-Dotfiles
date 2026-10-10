pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of fraud: the theatre. Red velvet curtains drawn aside, a pelmet with
// a gold fringe and the two masks over the stage; the view is printed on the playbill pinned in
// the middle. Who is playing whom — you will not find out from it.
HellDress {
    id: dress

    paper: "#ece0bf"
    ink: "#1b1410"
    redInk: "#8c1d2b"
    title: I18n.t("Афиша · в ролях: настройки", "Playbill · starring: Settings")
    titleColor: "#e2c26a"
    closer: "#5a0f18"
    closerInk: "#e2c26a"
    headHeight: Theme.u * 24
    pageX: Theme.u * 34
    pageRight: Theme.u * 34
    pageTop: headHeight + Theme.u * 6
    pageBottom: Theme.u * 10

    // the dark of the stage
    Rectangle {
        anchors.fill: parent
        color: "#0c0809"
    }
    // the curtains: velvet folds either side
    Repeater {
        model: 2
        Row {
            id: curtain
            required property int index
            x: index ? dress.width - width : 0
            y: dress.headHeight - Theme.u * 4
            Repeater {
                model: 6
                Rectangle {
                    required property int index
                    width: Theme.u * 5
                    height: dress.height - dress.headHeight + Theme.u * 4
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: "#4a0a14"
                        }
                        GradientStop {
                            position: 0.5
                            color: index % 2 ? "#8c1d2b" : "#7a1624"
                        }
                        GradientStop {
                            position: 1
                            color: "#3a0810"
                        }
                    }
                }
            }
        }
    }
    // the pelmet and its fringe
    Rectangle {
        width: dress.width
        height: dress.headHeight
        color: "#6e1220"
        border.width: Math.max(1, Theme.u / 2)
        border.color: "#3a0810"
    }
    Row {
        y: dress.headHeight
        Repeater {
            model: Math.ceil(dress.width / (Theme.u * 3))
            Rectangle {
                required property int index
                width: Theme.u * 3
                height: Theme.u * (index % 2 ? 3 : 4)
                color: index % 2 ? "#b8902e" : "#e2c26a"
            }
        }
    }
    // the masks: comedy and tragedy
    Repeater {
        model: 2
        PxIcon {
            required property int index
            bitmap: index ? [".#####.", "#wwwww#", "#w#w#w#", "#wwwww#", "#ww#ww#", "#w###w#", ".#www#."] : [".#####.", "#wwwww#", "#w#w#w#", "#wwwww#", "#w###w#", "#ww#ww#", ".#www#."]
            pixel: Math.max(1, Theme.u * 1.5)
            ink: "#3a0810"
            light: index ? "#c9c0a8" : "#ece0bf"
            x: index ? dress.width - width - Theme.u * 24 : Theme.u * 10
            y: (dress.headHeight - height) / 2
        }
    }
    // the pins in the playbill's corners
    Repeater {
        model: 2
        Rectangle {
            required property int index
            z: 2
            x: index ? dress.width - dress.pageRight - width - Theme.u * 2 : dress.pageX + Theme.u * 2
            y: dress.pageTop + Theme.u * 2
            width: Theme.u * 3
            height: width
            radius: width / 2
            color: "#b8902e"
        }
    }
}
