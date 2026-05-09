import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../theme"
import "."

Pill {
    id: root
    
    readonly property bool enabled: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    
    function getConnectedName() {
        for (var i = 0; i < Bluetooth.devices.count; i++) {
            var dev = Bluetooth.devices.get(i);
            if (dev.connected) return dev.name;
        }
        return "";
    }
    
    readonly property string connectedName: getConnectedName()
    readonly property bool connected: connectedName !== ""
    
    content: [
        Text {
            text: !enabled ? "󰂲" : (connected ? "󰂱" : "󰂯")
            color: enabled ? barWindow.accentColor : Colors.grey500
            font.pixelSize: 16
            font.weight: Font.Bold
            opacity: enabled ? 1.0 : 0.6
        }
    ]

    Timer {
        id: tooltipTimer
        interval: 400
        onTriggered: {
            var pos = root.mapToGlobal(0, 0)
            SessionState.showTooltip(
                connected ? connectedName : (enabled ? "Bluetooth On" : "Bluetooth Off"),
                pos.x, pos.y, root.width, root.height
            )
        }
    }

    Component.onCompleted: {
        if (mouseArea) {
            mouseArea.entered.connect(() => tooltipTimer.start())
            mouseArea.exited.connect(() => {
                tooltipTimer.stop()
                SessionState.hideTooltip()
            })
        }
    }
    
    onClicked: {
        if (SessionState.bluetoothPopupVisible) {
            SessionState.bluetoothPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.bluetoothPopupVisible = true
        }
    }

    onRightClicked: {
        if (enabled) {
            Quickshell.execDetached(["bluetoothctl", "power", "off"])
        } else {
            Quickshell.execDetached(["rfkill", "unblock", "bluetooth"])
            Quickshell.execDetached(["bluetoothctl", "power", "on"])
        }
    }
}
