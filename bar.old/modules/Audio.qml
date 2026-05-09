import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "."

Pill {
    id: root
    
    readonly property int volume: AudioState.volume
    readonly property bool muted: AudioState.muted
    
    content: [
        Text {
            text: muted || volume === 0 ? "󰝟" : (volume < 33 ? "󰕿" : (volume < 66 ? "󰖀" : "󰕾"))
            color: muted ? Colors.grey500 : barWindow.accentColor
            font.pixelSize: 16
            font.weight: Font.Bold
        },
        Text {
            text: volume + "%"
            color: Colors.white
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    ]

    Timer {
        id: tooltipTimer
        interval: 400
        onTriggered: {
            var pos = root.mapToGlobal(0, 0)
            SessionState.showTooltip(
                muted ? "Muted" : "Volume: " + volume + "%",
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
        if (AudioState.popupVisible) {
            AudioState.hide()
        } else {
            SessionState.closeAllPopups()
            AudioState.show()
        }
    }

    onRightClicked: AudioState.setMute(!AudioState.muted)
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            var newVol = wheel.angleDelta.y > 0
                ? Math.min(100, volume + 5)
                : Math.max(0, volume - 5)
            AudioState.setVolume(newVol)
        }
    }
}
