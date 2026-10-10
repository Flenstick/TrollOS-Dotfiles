import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// TrollOS: the card at the top of Settings — picture and name. The picture is
// copied to ~/.config/angelos/avatar-<time>.<ext>, so it stays when the
// original is moved; the Windows 11 Start menu shows it too.
PxPage {
    id: page

    heading: I18n.t("Профиль", "Profile")
    subtitle: I18n.t("Аватарка и имя наверху настроек и в Пуске раскладки Windows 11.", "The picture and name at the top of Settings and in the Windows 11 layout's Start menu.")

    property bool picking: false
    readonly property string accountName: Shell.settingsView ? Shell.settingsView.accountName : WinStyle.userName

    function pick() {
        if (picking)
            return;
        picking = true;
        picker.running = true;
    }
    function reset() {
        Config.profile.avatar = "";
        cleaner.running = true;
    }

    // a file dialog (zenity, else kdialog); the picture is copied next to settings.json
    Process {
        id: picker
        command: ["sh", "-c", 'f=""; if command -v zenity >/dev/null; then f=$(zenity --file-selection --title="$1" --file-filter="$2 | *.png *.jpg *.jpeg *.gif *.webp *.bmp *.avif *.PNG *.JPG *.JPEG" 2>/dev/null); elif command -v kdialog >/dev/null; then f=$(kdialog --title "$1" --getopenfilename "$HOME" "*.png *.jpg *.jpeg *.gif *.webp *.bmp *.avif|$2" 2>/dev/null); fi; [ -n "$f" ] && [ -f "$f" ] || exit 1; ext=$(printf %s "${f##*.}" | tr "A-Z" "a-z"); dir="$3"; dest="$dir/avatar-$(date +%s).$ext"; mkdir -p "$dir" && cp -- "$f" "$dest" || exit 2; for o in "$dir"/avatar-*; do [ "$o" = "$dest" ] || rm -f -- "$o"; done; printf %s "$dest"', "sh", I18n.t("Аватарка TrollOS", "TrollOS picture"), I18n.t("Картинки", "Pictures"), Config.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const dest = text.trim();
                if (dest)
                    Config.profile.avatar = dest;
            }
        }
        onExited: page.picking = false
    }
    Process {
        id: cleaner
        command: ["sh", "-c", 'rm -f -- "$1"/avatar-*', "sh", Config.dir]
    }

    PxGroup {
        title: I18n.t("Аватарка", "Picture")
        width: parent.width

        Row {
            spacing: Theme.u * 10
            TrollAvatar {
                size: Theme.u * 56
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.u * 4
                PxButton {
                    icon: "image"
                    accent: true
                    enabled: !page.picking
                    text: page.picking ? I18n.t("выбираю…", "choosing…") : I18n.t("Выбрать картинку…", "Choose a picture…")
                    onClicked: page.pick()
                }
                PxButton {
                    visible: !!Config.profile.avatar
                    icon: "splat"
                    text: I18n.t("Вернуть кляксу", "Back to the splat")
                    onClicked: page.reset()
                }
                PxText {
                    text: I18n.t("PNG, JPG, GIF или WebP — обрежется до квадрата", "PNG, JPG, GIF or WebP — cropped to a square")
                    kind: "tiny"
                    dim: true
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Имя", "Name")
        width: parent.width

        SettingRow {
            label: I18n.t("Как тебя показывать", "Shown as")
            hint: I18n.t("пусто — имя учётной записи: ", "empty — the account name: ") + page.accountName
            PxField {
                width: parent.width
                text: Config.profile.name
                placeholder: page.accountName
                onEdited: Config.profile.name = text.trim()
            }
        }
    }
}
