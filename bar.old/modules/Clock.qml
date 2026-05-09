import QtQuick
import Quickshell
import "../theme"
import "."

Pill {
    id: root
    
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
    
    property bool showDate: false
    
    content: [
        Text {
            id: iconText
            text: root.showDate ? "󰸗" : "󱑒"
            color: barWindow.accentColor
            font.pixelSize: 16
            font.weight: Font.Bold
            
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: iconText; property: "opacity"; to: 0; duration: 100 }
                    PropertyAction { }
                    NumberAnimation { target: iconText; property: "opacity"; to: 1; duration: 100 }
                }
            }
        },
        Text {
            id: timeText
            text: root.showDate ? Qt.formatDateTime(systemClock.date, "ddd d MMM") : Qt.formatDateTime(systemClock.date, "HH:mm")
            color: Colors.white
            font.pixelSize: 14
            font.weight: Font.Bold
            font.family: "Inter, Roboto, sans-serif"
            
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: timeText; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InOutQuad }
                    PropertyAction { }
                    NumberAnimation { target: timeText; property: "opacity"; to: 1; duration: 150; easing.type: Easing.InOutQuad }
                }
            }
        }
    ]
    
    onRightClicked: showDate = !showDate
}
