import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root
    property string previewUrl: ""
    property string gifUrl: ""
    property string title: ""
    property bool rootHover: false

    signal selected(string url)

    readonly property color colorSurface: "#1e1e1e"
    readonly property color colorSurfaceVariant: "#2d2d2d"
    readonly property color colorAccent: "#3d5afe"
    readonly property int borderRadius: 8

    Rectangle {
        id: itemRoot
        anchors.fill: parent
        anchors.margins: 4
        color: activeFocus ? Qt.rgba(0.24, 0.35, 1.0, 0.2) : (rootHover ? colorSurfaceVariant : "#1a1a1a")
        radius: borderRadius
        focus: true
        
        border.color: activeFocus ? colorAccent : (rootHover ? "#444" : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: rootHover = true
            onExited: rootHover = false
            onClicked: {
                root.forceActiveFocus()
                root.selected(gifUrl)
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            color: "#111"
            radius: borderRadius - 2
            clip: true

            AnimatedImage {
                anchors.fill: parent
                source: previewUrl
                fillMode: AnimatedImage.PreserveAspectCrop
                asynchronous: true
                playing: rootHover || activeFocus
                
                onStatusChanged: {
                    if (status === AnimatedImage.Error) {
                        console.log("Error loading GIF:", source)
                    }
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                visible: parent.children[0].status === AnimatedImage.Loading
                width: 24
                height: 24
            }

            // Title overlay on hover
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 30
                color: Qt.rgba(0,0,0,0.7)
                visible: rootHover || activeFocus
                
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 10
                    text: title
                    color: "white"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
