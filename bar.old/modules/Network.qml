import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "."

Pill {
    id: root
    
    readonly property bool connected: NetworkState.connected
    readonly property string ssid: NetworkState.activeSSID
    readonly property int signal: NetworkState.activeSignal
    
    function getIcon() {
        if (!NetworkState.wifiEnabled) return "󰤭"
        if (!connected) return "󰤯"
        if (signal >= 80) return "󰤨"
        if (signal >= 60) return "󰤥"
        if (signal >= 40) return "󰤢"
        if (signal >= 20) return "󰤟"
        return "󰤯"
    }
    
    content: [
        Text {
            text: getIcon()
            color: NetworkState.wifiEnabled ? barWindow.accentColor : Colors.grey500
            font.pixelSize: 16
            font.weight: Font.Bold
        }
    ]

    Timer {
        id: tooltipTimer
        interval: 400
        onTriggered: {
            var pos = root.mapToGlobal(0, 0)
            SessionState.showTooltip(
                connected ? ssid : (NetworkState.wifiEnabled ? "Wi-Fi On" : "Wi-Fi Off"),
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
        if (SessionState.wifiPopupVisible) {
            SessionState.wifiPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.wifiPopupVisible = true
        }
    }

    onRightClicked: NetworkState.toggleWifi()
}
