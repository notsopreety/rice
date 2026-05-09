import QtQuick
import Quickshell
import Quickshell.Io
import QtCore

import QtQuick.Layouts
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Widgets
  
FocusScope {
    property var activeIndex: historyView.currentIndex === index 
    property alias clearBtn: clearItemBtn
    property alias itemRoot: itemRoot
    property bool rootHover: false
    property bool isImage: checkIsImage(model.text)
    property string imagePath: ""
    property string tempPath: ""
    property var imageInfo: undefined

    id: listFocus
    height: isImage ? 80 : 60

    Component.onCompleted: {
        if(isImage) handleImage(model)
        if(isSearching){
            Qt.callLater(() => {
                searchInput.forceActiveFocus()
                isSearching = false
            })
        }
    }

    Component.onDestruction: {
        if (imagePath !== "") {
            console.log("removing", imagePath)
            imageProcess.command = ["bash", "-c", `rm ${imagePath}`]
            imageProcess.startDetached()
        }
    }

    Process {
        id: imageProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("saved temp image", tempPath)
                imagePath = tempPath
            }
        }
    }

    readonly property color colorSurface: "#1e1e1e"
    readonly property color colorSurfaceVariant: "#2d2d2d"
    readonly property color colorAccent: "#3d5afe"
    readonly property color colorText: "#ffffff"
    readonly property color colorTextDim: "#b0b0b0"
    readonly property int borderRadius: 10

    Rectangle {
        id: itemRoot
        anchors.fill: listFocus
        color: activeFocus ? Qt.rgba(0.24, 0.35, 1.0, 0.2) : (rootHover ? colorSurfaceVariant : "transparent")
        radius: borderRadius
        focus: true
        
        border.color: activeFocus ? colorAccent : (rootHover ? "#444" : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        KeyNavigation.tab: clearItemBtn

        MouseArea {
            id: itemContainerMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: rootHover = true
            onExited: rootHover = false
            onClicked: pasteSelected(model)
        }

        Item {
            focus: false
            anchors.fill: parent
            anchors.margins: 10

            Loader {
                id: contentLoader
                anchors.fill: parent
                anchors.rightMargin: 30
                sourceComponent: isImage ? imageComponent : textComponent
            }

            Component {
                id: textComponent
                Text {
                    focus: false
                    anchors.fill: parent
                    text: model.text
                    color: colorText
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Component {
                id: imageComponent
                RowLayout {
                    spacing: 12
                    anchors.fill: parent
                    
                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        color: "#252525"
                        radius: 6
                        clip: true
                        
                        BusyIndicator {
                            anchors.centerIn: parent
                            running: imagePath === ""
                            width: 20
                            height: 20
                        }
                        
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: imagePath
                            fillMode: Image.PreserveAspectFit
                            visible: imagePath !== ""
                            asynchronous: true
                            sourceSize.width: 120
                            sourceSize.height: 120
                        }
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Image (" + (imageInfo?.format.toUpperCase() || "") + ")"
                            color: colorText
                            font.bold: true
                            font.pixelSize: 13
                        }
                        
                        Text {
                            text: imageInfo?.dimensions || ""
                            color: colorTextDim
                            font.pixelSize: 11
                        }
                        
                        Text {
                            text: imageInfo?.size || ""
                            color: Qt.rgba(1,1,1,0.4)
                            font.pixelSize: 10
                        }
                    }
                }
            }

            AbstractButton {
                id: clearItemBtn
                onPressed: removeSelected(model, index)
                Keys.onReturnPressed: removeSelected(model, index)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 28
                implicitWidth: 28
                focus: true

                background: Rectangle {
                    color: clearItemBtn.hovered || clearItemBtn.activeFocus ? Qt.rgba(1,1,1,0.1) : "transparent"
                    radius: 14
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                contentItem: Text {
                    text: "󰆴"
                    color: clearItemBtn.hovered || clearItemBtn.activeFocus ? "#ff5252" : colorTextDim
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                KeyNavigation.tab: clearAllBtn
            }
        }
    }

    function handleImage(model) {
        if(!isImage) return

        const match = model.text.match(/^\[\[ binary data (.+?) (.+?) (.+?) (\d+x\d+) \]\]$/i)
        
        imageInfo = {
            size: match[1] + " " + match[2],
            format: match[3].toLowerCase(),
            dimensions: match[4]
        }
        
        tempPath = `/tmp/clipboard-img-${model.id}-${Date.now()}.${imageInfo.format}`
        imageProcess.exec(["bash", "-c", `printf '${model.id}' | cliphist decode > ${tempPath}`])
    } 
}