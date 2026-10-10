import QtQuick
import Quickshell.Io
import "."

// IPC: qs -c angelos ipc call caffeine toggle|on|off|status
Item {
    property var plugin

    IpcHandler {
        target: "caffeine"
        function toggle(): void {
            CaffeineState.toggle();
        }
        function on(): void {
            if (!CaffeineState.active)
                CaffeineState.toggle();
        }
        function off(): void {
            if (CaffeineState.active)
                CaffeineState.toggle();
        }
        function status(): string {
            return CaffeineState.active ? "on" : "off";
        }
    }
}
