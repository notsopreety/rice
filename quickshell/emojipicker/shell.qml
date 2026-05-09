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
    WlrLayershell.namespace: "emojipicker"
    exclusionMode: ExclusionMode.Ignore
    
    property string filterQuery: ""
    property var allEmojis: []
    property var initialX: null
    property var initialY: null
    property int popUpWidth: 400
    property int popUpHeight: 500

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
        id: emojiModel
    }

    Timer {
        id: filterTimer
        interval: 100
        onTriggered: updateFilteredEmojis()
    }

    FileView {
        path: Quickshell.shellPath("emojis.json")
        JsonAdapter {
            id: emojiDataAdapter
            property var emojis: []
            onEmojisChanged: {
                if (emojis) {
                    allEmojis = emojis
                    updateFilteredEmojis()
                }
            }
        }
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

                Label {
                    text: "Emoji Picker"
                    color: colorText
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search emojis..."
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
                        filterTimer.restart()
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            emojiGrid.forceActiveFocus()
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
                        id: emojiGrid
                        model: emojiModel
                        cellWidth: 46
                        cellHeight: 46
                        anchors.fill: parent
                        boundsBehavior: Flickable.StopAtBounds
                        focus: true

                        delegate: EmojiItem {
                            emoji: model.emoji
                            name: model.name
                            isCurrent: emojiGrid.currentIndex === index
                            onSelected: (emoji) => selectEmoji(emoji)
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                                if (currentIndex >= 0) {
                                    selectEmoji(emojiModel.get(currentIndex).emoji)
                                }
                                event.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }

    function updateFilteredEmojis() {
        emojiModel.clear()
        const query = filterQuery.toLowerCase().trim()
        let count = 0
        for (let i = 0; i < allEmojis.length; i++) {
            const item = allEmojis[i]
            if (query === "" || 
                item.name.toLowerCase().includes(query) || 
                item.shortname.toLowerCase().includes(query) ||
                item.category.toLowerCase().includes(query)) {
                emojiModel.append(item)
                count++
                if (count > 200) break // Limit display for performance
            }
        }
        if (emojiModel.count > 0) emojiGrid.currentIndex = 0
    }

    function selectEmoji(emoji) {
        Quickshell.execDetached(["bash", "-c", `printf '${emoji}' | wl-copy && hyprctl dispatch sendshortcut CTRL, V, activewindow`])
        Qt.quit()
    }
}
