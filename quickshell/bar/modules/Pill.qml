pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts

Rectangle {
    id: root

    property alias mouseArea: mouseArea
    property color pillBg: Qt.rgba(barWindow.surfaceColor.r, barWindow.surfaceColor.g, barWindow.surfaceColor.b, 0.5)
    property int padding: 10

    implicitWidth: layout.implicitWidth + (padding * 2)
    implicitHeight: parent ? parent.height - 8 : 32

    radius: 12
    color: pillBg

    border.width: 1
    border.color: mouseArea.containsMouse
        ? Qt.rgba(barWindow.accentColor.r, barWindow.accentColor.g, barWindow.accentColor.b, 0.5)
        : Qt.rgba(barWindow.accentColor.r, barWindow.accentColor.g, barWindow.accentColor.b, 0.15)

    scale: mouseArea.pressed ? 0.96 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }
    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: 8
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked()
            } else {
                root.clicked()
            }
        }
    }

    signal clicked()
    signal rightClicked()
}