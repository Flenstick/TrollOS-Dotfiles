pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// TrollOS: screen time like GNOME's Wellbeing — a day, a week, a month or a
// year, back as far as it was counted (services/ScreenTime).
PxPage {
    id: page

    heading: I18n.t("Экранное время", "Screen time")
    subtitle: I18n.t("Сколько ты за компьютером и в каких приложениях. Хранится только на этом компьютере.", "How long you're at the computer and in which apps. Kept on this computer only.")

    property string period: "week"          // day | week | month | year
    property int offset: 0                   // 0: this one, -1: the one before…
    property int hovered: -1
    onPeriodChanged: {
        offset = 0;
        hovered = -1;
    }
    onOffsetChanged: hovered = -1

    readonly property var monthsShort: I18n.t(["янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"], ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
    readonly property var weekdays: I18n.t(["пн", "вт", "ср", "чт", "пт", "сб", "вс"], ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])

    // the chosen span: {from, to, title}
    readonly property var span: {
        ScreenTime.rev;
        const t = new Date();
        const today = new Date(t.getFullYear(), t.getMonth(), t.getDate());
        if (period === "day") {
            const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() + offset);
            return {
                "from": d,
                "to": d,
                "title": offset === 0 ? I18n.t("Сегодня", "Today") : offset === -1 ? I18n.t("Вчера", "Yesterday") : d.getDate() + " " + monthsShort[d.getMonth()] + (d.getFullYear() !== today.getFullYear() ? " " + d.getFullYear() : "")
            };
        }
        if (period === "week") {
            const from = new Date(today.getFullYear(), today.getMonth(), today.getDate() - (today.getDay() + 6) % 7 + offset * 7);
            const to = new Date(from.getFullYear(), from.getMonth(), from.getDate() + 6);
            return {
                "from": from,
                "to": to,
                "title": offset === 0 ? I18n.t("Эта неделя", "This week") : from.getDate() + " " + monthsShort[from.getMonth()] + " – " + to.getDate() + " " + monthsShort[to.getMonth()]
            };
        }
        if (period === "month") {
            const from = new Date(today.getFullYear(), today.getMonth() + offset, 1);
            const to = new Date(from.getFullYear(), from.getMonth() + 1, 0);
            const name = Qt.locale(I18n.t("ru_RU", "en_US")).standaloneMonthName(from.getMonth());
            return {
                "from": from,
                "to": to,
                "title": name.charAt(0).toUpperCase() + name.slice(1) + " " + from.getFullYear()
            };
        }
        const y = today.getFullYear() + offset;
        return {
            "from": new Date(y, 0, 1),
            "to": new Date(y, 11, 31),
            "title": String(y)
        };
    }
    readonly property string todayKey: ScreenTime.dayKey()
    readonly property var dayList: ScreenTime.range(span.from, span.to)
    readonly property var keys: dayList.map(d => d.key)
    // the bars of the chart: [{label, s, current, tip}]
    readonly property var bars: {
        if (period === "day") {
            const now = new Date().getHours();
            return ScreenTime.hours(keys[0]).map((s, i) => ({
                        "label": i % 6 === 0 ? i + ":00" : "",
                        "s": s,
                        "current": offset === 0 && i === now,
                        "tip": i + ":00–" + (i + 1) + ":00"
                    }));
        }
        if (period === "year")
            return ScreenTime.months(span.from.getFullYear()).map(m => ({
                        "label": monthsShort[m.month],
                        "s": m.s,
                        "current": offset === 0 && m.month === new Date().getMonth(),
                        "tip": monthsShort[m.month] + " " + span.from.getFullYear()
                    }));
        return dayList.map((d, i) => ({
                    "label": period === "week" ? weekdays[i] : d.date.getDate() === 1 || d.date.getDate() % 5 === 0 ? String(d.date.getDate()) : "",
                    "s": d.s,
                    "current": d.key === todayKey,
                    "tip": weekdays[(d.date.getDay() + 6) % 7] + ", " + d.date.getDate() + " " + monthsShort[d.date.getMonth()]
                }));
    }
    readonly property real total: dayList.reduce((a, d) => a + d.s, 0)
    readonly property real maxBar: Math.max(60, ...bars.map(b => b.s))
    // the average over the days that had any time (a day: over the 7 days before it)
    readonly property real average: {
        const list = period === "day" ? ScreenTime.range(new Date(span.from.getFullYear(), span.from.getMonth(), span.from.getDate() - 7), new Date(span.from.getFullYear(), span.from.getMonth(), span.from.getDate() - 1)) : dayList;
        const used = list.filter(d => d.s > 60 && d.key <= todayKey);
        return used.length ? used.reduce((a, d) => a + d.s, 0) / used.length : 0;
    }
    readonly property var apps: ScreenTime.topApps(keys, 8)
    readonly property bool canNext: offset < 0

    property bool confirmClear: false
    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: page.confirmClear = false
    }

    PxGroup {
        width: parent.width

        // period and the arrows
        Item {
            width: parent.width
            height: periodSeg.height
            PxSegmented {
                id: periodSeg
                currentValue: page.period
                model: [
                    {
                        "label": I18n.t("День", "Day"),
                        "value": "day"
                    },
                    {
                        "label": I18n.t("Неделя", "Week"),
                        "value": "week"
                    },
                    {
                        "label": I18n.t("Месяц", "Month"),
                        "value": "month"
                    },
                    {
                        "label": I18n.t("Год", "Year"),
                        "value": "year"
                    }
                ]
                onActivated: v => page.period = v
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.u * 2
                PxButton {
                    compact: true
                    icon: "arrowLeft"
                    onClicked: page.offset--
                }
                PxButton {
                    compact: true
                    icon: "arrowRight"
                    enabled: page.canNext
                    onClicked: page.offset++
                }
            }
        }

        // the total
        Column {
            width: parent.width
            spacing: Theme.u
            PxText {
                text: page.span.title
                dim: true
            }
            PxText {
                text: ScreenTime.fmt(page.total)
                kind: "big"
                color: Theme.dark ? Theme.text : Theme.edge
            }
            PxText {
                visible: page.average > 0
                text: (page.period === "day" ? I18n.t("в среднем за прошлую неделю ", "last week's average ") : I18n.t("в среднем ", "on average ")) + ScreenTime.fmt(page.average) + I18n.t(" в день", " a day")
                kind: "tiny"
                dim: true
            }
        }

        // the chart
        Item {
            id: chart
            width: parent.width
            height: Theme.u * 62
            readonly property int labelH: Theme.u * 9
            readonly property int gap: page.bars.length > 20 ? Theme.u : Theme.u * 3
            readonly property real barW: (width - gap * (page.bars.length - 1)) / Math.max(1, page.bars.length)
            readonly property int plotH: height - labelH - Theme.u * 10

            // the hovered bar's value (else the largest one's)
            PxText {
                readonly property var b: page.hovered >= 0 ? page.bars[page.hovered] : null
                text: b ? b.tip + " · " + ScreenTime.fmt(b.s) : ""
                kind: "tiny"
                color: Theme.accent
            }
            Repeater {
                model: page.bars
                Item {
                    id: bar
                    required property var modelData
                    required property int index
                    x: index * (chart.barW + chart.gap)
                    y: Theme.u * 10
                    width: chart.barW
                    height: chart.plotH
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(bar.modelData.s > 0 ? Theme.u * 2 : Theme.u, parent.height * bar.modelData.s / page.maxBar)
                        color: bar.modelData.current ? Theme.accent : page.hovered === bar.index ? Theme.mix(Theme.face, Theme.accent, 0.7) : bar.modelData.s > 0 ? Theme.mix(Theme.face, Theme.accent, 0.42) : Theme.mix(Theme.face, Theme.text, 0.12)
                        border.width: bar.modelData.s > 0 ? Theme.u : 0
                        border.color: Theme.edge
                    }
                    PxText {
                        y: parent.height + Theme.u * 2
                        width: Math.max(implicitWidth, parent.width)
                        x: (parent.width - width) / 2
                        horizontalAlignment: Text.AlignHCenter
                        text: bar.modelData.label
                        kind: "tiny"
                        dim: !bar.modelData.current
                        color: bar.modelData.current ? Theme.accent : Theme.textDim
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: page.hovered = bar.index
                        onExited: if (page.hovered === bar.index)
                            page.hovered = -1
                    }
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Приложения", "Apps")
        width: parent.width

        PxText {
            visible: page.apps.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            text: Config.screenTime.apps ? I18n.t("Пока пусто — время появится, как только посидишь за компьютером.", "Nothing yet — time shows up once you use the computer.") : I18n.t("Учёт по приложениям выключен.", "Per-app counting is off.")
            dim: true
        }
        Repeater {
            model: page.apps
            Item {
                id: app
                required property var modelData
                width: parent.width
                height: Theme.u * 13
                AppIcon {
                    id: appIcon
                    anchors.verticalCenter: parent.verticalCenter
                    appId: app.modelData.id
                    size: Theme.u * 9
                }
                PxText {
                    id: appName
                    anchors.left: appIcon.right
                    anchors.leftMargin: Theme.u * 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Theme.u * 80, parent.width * 0.3)
                    text: app.modelData.name
                    elide: Text.ElideRight
                }
                Rectangle {
                    anchors.left: appName.right
                    anchors.leftMargin: Theme.u * 4
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property real room: parent.width - appName.width - appIcon.width - appTime.width - Theme.u * 16
                    width: Math.max(Theme.u * 2, room * app.modelData.s / Math.max(1, page.apps[0].s))
                    height: Theme.u * 4
                    color: Theme.mix(Theme.face, Theme.accent, 0.55)
                    border.width: Theme.u / 2
                    border.color: Theme.edge
                }
                PxText {
                    id: appTime
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.u * 40
                    horizontalAlignment: Text.AlignRight
                    text: ScreenTime.fmt(app.modelData.s)
                    dim: true
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Учёт", "Counting")
        width: parent.width

        SettingRow {
            label: I18n.t("Считать экранное время", "Count screen time")
            hint: I18n.t("пока ты за компьютером и он не заблокирован; видео тоже считается", "while you're at the computer and it's unlocked; a video counts too")
            PxToggle {
                checked: Config.screenTime.track
                onToggled: c => Config.screenTime.track = c
            }
        }
        SettingRow {
            label: I18n.t("По приложениям", "Per app")
            hint: I18n.t("какое окно было в фокусе", "which window had the focus")
            PxToggle {
                checked: Config.screenTime.apps
                onToggled: c => Config.screenTime.apps = c
            }
        }
        SettingRow {
            label: I18n.t("История", "History")
            hint: ScreenTime.firstDay ? I18n.t("считается с ", "counted since ") + ScreenTime.firstDay.split("-").reverse().join(".") + " · ~/.local/state/angelos/screen-time.json" : "~/.local/state/angelos/screen-time.json"
            PxButton {
                danger: page.confirmClear
                icon: "trash"
                text: page.confirmClear ? I18n.t("Точно стереть? Нажми ещё раз", "Really? Click again") : I18n.t("Стереть историю", "Clear history")
                onClicked: {
                    if (!page.confirmClear) {
                        page.confirmClear = true;
                        confirmTimer.restart();
                    } else {
                        ScreenTime.clear();
                        page.confirmClear = false;
                    }
                }
            }
        }
    }
}
