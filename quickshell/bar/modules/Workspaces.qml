pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: wsRow.width
    implicitHeight: 28

    Row {
        id: wsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: 10

            Rectangle {
                required property int index
                property int wsNum: index + 1

                width: 28
                height: 28
                radius: 8
                color: wsNum === 1 ? barWindow.accentColor : barWindow.surfaceColor
                opacity: wsNum === 1 ? 1.0 : 0.6

                Text {
                    anchors.centerIn: parent
                    text: wsNum.toString()
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: wsNum === 1 ? barWindow.bgColor : barWindow.textColor
                }

                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}