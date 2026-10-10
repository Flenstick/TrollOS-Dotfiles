pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Per-screen workspace switch effects: NGO popup + side heart strip.
Variants {
    model: Shell.screens

    Scope {
        id: scope
        required property var modelData
        readonly property string screenName: modelData.name

        property var ws: null
        property int serial: 0

        Connections {
            target: Niri
            function onWorkspaceActivated(ws, focused) {
                if (ws.output !== scope.screenName || Niri.overviewOpen)
                    return;
                scope.ws = ws;
                scope.serial++;
            }
        }

        WorkspacePopup {
            screen: scope.modelData
            ws: scope.ws
            serial: scope.serial
        }
        WorkspaceStrip {
            screen: scope.modelData
            screenName: scope.screenName
            serial: scope.serial
        }
        SwitchFx {
            screen: scope.modelData
            screenName: scope.screenName
        }
    }
}
