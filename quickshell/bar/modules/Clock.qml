pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: contentRow.width
    implicitHeight: 32

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "access_time"
            font.family: "Material Icons"
            font.pixelSize: 16
            color: barWindow.accentColor
        }

        Text {
            id: timeText
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(new Date(), "HH:mm")
            font.pixelSize: 14
            font.weight: Font.Medium
            color: barWindow.textColor

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(new Date(), "EEE d")
            font.pixelSize: 12
            color: barWindow.mutedColor
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
    }
}