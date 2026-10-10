#!/bin/sh
# Подключение телефона к adb по Wi-Fi (беспроводная отладка Android 11+) для scrcpy.
# Телефон ищем через avahi: adb из Arch собран без mDNS.
#   mirror.sh connect      → печатает «ok <serial>» | «need-wifi» | «need-pair»
#   mirror.sh pair <код>   → «ok <serial>» | «no-pair-service» | «pair-failed <текст>»
# Последняя строка вывода — ответ.

find_service() { # $1 = _adb-tls-connect._tcp | _adb-tls-pairing._tcp → «ip:port»
    timeout 4 avahi-browse -rpt "$1" 2>/dev/null |
        awk -F';' '$1=="=" && $3=="IPv4" {print $8":"$9; exit}'
}

current() { # уже подключённый телефон (по Wi-Fi или USB)
    adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1; exit}'
}

connect() {
    s=$(current)
    [ -n "$s" ] && { echo "ok $s"; return 0; }
    addr=$(find_service _adb-tls-connect._tcp)
    [ -z "$addr" ] && { echo "need-wifi"; return 1; }
    out=$(timeout 8 adb connect "$addr" 2>&1)
    echo "$out" >&2
    sleep 0.5
    s=$(current)
    [ -n "$s" ] && { echo "ok $s"; return 0; }
    # служба есть, но компьютер ещё не спарен с телефоном
    adb disconnect "$addr" >/dev/null 2>&1
    echo "need-pair"
    return 1
}

case "$1" in
connect)
    adb start-server >/dev/null 2>&1
    connect
    ;;
pair)
    adb start-server >/dev/null 2>&1
    addr=$(find_service _adb-tls-pairing._tcp)
    [ -z "$addr" ] && { echo "no-pair-service"; exit 1; }
    out=$(timeout 15 adb pair "$addr" "$2" 2>&1)
    echo "$out" >&2
    case "$out" in
    *Successfully*) ;;
    *) echo "pair-failed $(echo "$out" | tail -n1)"; exit 1 ;;
    esac
    # после спаривания телефон объявляет службу подключения не сразу
    for _ in 1 2 3 4 5; do
        connect >/dev/null 2>&1 && break
        sleep 1
    done
    connect
    ;;
*)
    echo "usage: $0 connect | pair <code>" >&2
    exit 2
    ;;
esac
