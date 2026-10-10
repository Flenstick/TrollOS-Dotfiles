import QtQuick
import Quickshell.Io
import "."

// IPC: qs -c angelos ipc call power get|menu|cycle|up|down|set <power-saver|balanced|performance>
Item {
    property var plugin

    IpcHandler {
        target: "power"
        function get(): string {
            return PowerMode.current.id;
        }
        function set(id: string): string {
            return PowerMode.set(id) ? id : "modes: " + PowerMode.available.map(m => m.id).join(", ");
        }
        function menu(): void {
            PowerMode.menuRequested();
        }
        function cycle(): string {
            PowerMode.cycle();
            return PowerMode.current.id;
        }
        function up(): void {
            PowerMode.step(1);
        }
        function down(): void {
            PowerMode.step(-1);
        }
    }
}
