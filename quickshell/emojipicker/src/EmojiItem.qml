import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root
    property string emoji: ""
    property string name: ""
    property bool isCurrent: false
    property bool rootHover: false

    signal selected(string emoji)

    width: 44
    height: 44

    readonly property color colorSurface: "#1e1e1e"
    readonly property color colorSurfaceVariant: "#2d2d2d"
    readonly property color colorAccent: "#3d5afe"
    readonly property color colorText: "#ffffff"
    readonly property int borderRadius: 8

    Rectangle {
        id: itemRoot
        anchors.fill: parent
        anchors.margins: 2
        color: activeFocus ? Qt.rgba(0.24, 0.35, 1.0, 0.2) : (rootHover ? colorSurfaceVariant : "transparent")
        radius: borderRadius
        focus: true
        
        border.color: activeFocus ? colorAccent : (rootHover ? "#444" : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: rootHover = true
            onExited: rootHover = false
            onClicked: {
                root.forceActiveFocus()
                root.selected(emoji)
            }
        }

        Text {
            anchors.centerIn: parent
            text: emoji
            font.pixelSize: 24
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        ToolTip.visible: rootHover
        ToolTip.text: name
        ToolTip.delay: 500
    }
}
