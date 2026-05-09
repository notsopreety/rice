import QtQuick
import Quickshell
import Quickshell.Io
import QtCore

import QtQuick.Layouts
import Quickshell.Wayland
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import "src"

PanelWindow {
    id: root
    visible: true
    color: "transparent"
    focusable: true
    aboveWindows: true
    WlrLayershell.namespace: "gifboard"
    exclusionMode: ExclusionMode.Ignore
    
    property string filterQuery: ""
    property var initialX: null
    property var initialY: null
    property int popUpWidth: 600
    property int popUpHeight: 500

    readonly property string apiKey: "Ztg4nr06u7HaKeygmhrnaj9OYxc2EX6x"
    readonly property color colorBg: "#121212"
    readonly property color colorSurface: "#1e1e1e"
    readonly property color colorAccent: "#3d5afe"
    readonly property color colorText: "#ffffff"
    readonly property color colorTextDim: "#b0b0b0"
    readonly property int borderRadius: 12

    anchors { 
        left: true  
        right: true  
        top: true
        bottom: true  
    }

    ListModel {
        id: gifModel
    }

    Timer {
        id: searchTimer
        interval: 500
        onTriggered: searchGifs()
    }

    Process {
        id: cursorCommand
        command: ["bash", "-c", "hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .x,.y,.width,.height' && hyprctl cursorpos"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: () => {
                const lines = this.text.trim().split('\n')
                if (lines.length >= 5) {
                    const monitorX = parseInt(lines[0])
                    const monitorY = parseInt(lines[1])
                    const monitorWidth = parseInt(lines[2])
                    const monitorHeight = parseInt(lines[3])
                    const [cursorX, cursorY] = lines[4].split(',').map(item => parseInt(item.trim()))
                    
                    const cursorOnMonitorX = cursorX - monitorX
                    const cursorOnMonitorY = cursorY - monitorY
                    
                    const finalX = cursorOnMonitorX + popUpWidth > monitorWidth 
                        ? monitorWidth - popUpWidth 
                        : cursorOnMonitorX
                    const finalY = cursorOnMonitorY + popUpHeight > monitorHeight 
                        ? monitorHeight - popUpHeight 
                        : cursorOnMonitorY
                    
                    initialX = finalX
                    initialY = finalY
                    popup.open()
                    searchGifs() // Initial trending or empty search
                }
            }
        }
    }

    Popup {
        id: popup
        x: initialX
        y: initialY
        implicitWidth: popUpWidth
        implicitHeight: popUpHeight
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: false
        focus: true
        padding: 0
        margins: 0
        
        background: Rectangle {
            color: colorBg
            radius: borderRadius
            border.color: "#333333"
            border.width: 1
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                samples: 25
                color: "#80000000"
            }
        }

        onClosed: Qt.quit()

        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "GIF Board"
                        color: colorText
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    BusyIndicator {
                        id: loadingIndicator
                        running: false
                        implicitWidth: 20
                        implicitHeight: 20
                    }
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search GIPHY..."
                    color: colorText
                    placeholderTextColor: colorTextDim
                    font.pixelSize: 14
                    padding: 10
                    leftPadding: 34
                    focus: true

                    background: Rectangle {
                        color: colorSurface
                        radius: 8
                        border.color: searchInput.activeFocus ? colorAccent : "#333333"
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: searchInput.activeFocus ? colorAccent : colorTextDim
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    onTextEdited: {
                        filterQuery = text
                        searchTimer.restart()
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            gifGrid.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AsNeeded
                        active: true
                        background: Rectangle { color: "transparent"; width: 6 }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: vbar.hovered ? colorAccent : Qt.rgba(1,1,1,0.2)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    GridView {
                        id: gifGrid
                        model: gifModel
                        cellWidth: (parent.width / 3)
                        cellHeight: 130
                        anchors.fill: parent
                        boundsBehavior: Flickable.StopAtBounds
                        focus: true

                        delegate: GifItem {
                            width: gifGrid.cellWidth
                            height: gifGrid.cellHeight
                            previewUrl: model.previewUrl
                            gifUrl: model.gifUrl
                            title: model.title
                            onSelected: (url) => selectGif(url)
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                                if (currentIndex >= 0) {
                                    selectGif(gifModel.get(currentIndex).gifUrl)
                                }
                                event.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }

    function searchGifs() {
        const query = filterQuery.trim()
        const endpoint = query === "" 
            ? `https://api.giphy.com/v1/gifs/trending?api_key=${apiKey}&limit=20`
            : `https://api.giphy.com/v1/gifs/search?q=${encodeURIComponent(query)}&api_key=${apiKey}&limit=20`

        loadingIndicator.running = true
        
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                loadingIndicator.running = false
                if (xhr.status === 200) {
                    const response = JSON.parse(xhr.responseText)
                    gifModel.clear()
                    response.data.forEach(gif => {
                        gifModel.append({
                            previewUrl: gif.images.fixed_height_small.url,
                            gifUrl: gif.images.original.url,
                            title: gif.title
                        })
                    })
                }
            }
        }
        xhr.open("GET", endpoint)
        xhr.send()
    }

    function selectGif(url) {
        // Use curl to pipe the GIF data to wl-copy with the correct type
        Quickshell.execDetached(["bash", "-c", `curl -s '${url}' | wl-copy --type image/gif && hyprctl dispatch sendshortcut CTRL, V, activewindow`])
        Qt.quit()
    }
}
