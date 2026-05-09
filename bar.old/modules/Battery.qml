import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"
import "."

Pill {
    id: root
    
    property var battery: UPower.displayDevice
    property bool hasBattery: battery && battery.ready
    property int pct: hasBattery ? Math.round(battery.percentage * 100) : 0
    property bool charging: hasBattery && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.FullyCharged
    )

    content: [
        Text {
            text: getIcon()
            color: barWindow.accentColor
            font.pixelSize: 16
            font.weight: Font.Bold
        },
        Text {
            text: pct + "%"
            color: Colors.white
            font.pixelSize: 13
            font.weight: Font.Bold
            visible: hasBattery
        }
    ]

    function getIcon() {
        if (!hasBattery) return "󰚥"
        if (charging) {
            if (pct >= 90) return "󰂅"
            if (pct >= 80) return "󰂋"
            if (pct >= 70) return "󰂊"
            if (pct >= 60) return "󰢞"
            if (pct >= 50) return "󰂉"
            if (pct >= 40) return "󰢝"
            if (pct >= 30) return "󰂈"
            if (pct >= 20) return "󰂇"
            if (pct >= 10) return "󰂆"
            return "󰢜"
        } else {
            if (pct >= 90) return "󰁹"
            if (pct >= 80) return "󰂂"
            if (pct >= 70) return "󰂁"
            if (pct >= 60) return "󰂀"
            if (pct >= 50) return "󰁿"
            if (pct >= 40) return "󰁾"
            if (pct >= 30) return "󰁽"
            if (pct >= 20) return "󰁼"
            if (pct >= 10) return "󰁻"
            return "󰁺"
        }
    }

    onClicked: {
        if (SessionState.powerPopupVisible) {
            SessionState.powerPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.powerPopupVisible = true
        }
    }
}
