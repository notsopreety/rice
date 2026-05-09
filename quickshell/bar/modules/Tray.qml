pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts

Row {
    id: root
    spacing: 2
    anchors.verticalCenter: parent.verticalCenter

    // System Tray Placeholder
    Item {
        width: 24
        height: 24

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: barWindow.accentColor
        }
    }

    // Quick Actions Menu Button
    Rectangle {
        id: menuBtn
        width: 32
        height: 28
        radius: 8
        color: "transparent"
        opacity: menuArea.containsMouse ? 0.8 : 0.4

        Text {
            anchors.centerIn: parent
            text: "more_horiz"
            font.family: "Material Icons"
            font.pixelSize: 18
            color: barWindow.textColor
        }

        MouseArea {
            id: menuArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
}