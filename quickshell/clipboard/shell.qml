import QtQuick
import Quickshell
import Quickshell.Io
import QtCore

import QtQuick.Layouts
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

import "src" 

PanelWindow {
    id: root
    visible: true
    color: "transparent"
    focusable: true
    aboveWindows: true
    WlrLayershell.namespace: `clipboard`
    exclusionMode: ExclusionMode.Ignore
    
    property var activeScreen: null
    property var fullClipboardArray: []
    property string filterQuery: ""
    property bool isSearching: false

    property var initialX: null
    property var initialY: null
    property var popUpWidth: 350
    property var popUpHeight: 430

    property Timer filterTimer: Timer {
        interval: 150
        onTriggered: updateFilteredItems()
    }
    
    anchors { 
        left: true  
        right: true  
        top: true
        bottom: true  
    }

    Settings {
        id: clipboardSettings
        category: "Clipboard"
    }

    ListModel  {
        id: clipboardHistory
    }

    Connections {
        target: Hyprland

        function onFocusedMonitorChanged(e) {
            const monitor = Hyprland.focusedMonitor
            if(!monitor) return
            if(activeScreen) return Qt.quit()
            
            if(!activeScreen) {
                for (const screen of Quickshell.screens) {
                    if (screen.name === monitor.name) {
                        activeScreen = screen
                    }
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
    
    Process {
        id: cliphistProccess
        command: ["cliphist", "list"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                const [_, id, __, text] = /(^\d{0,})(\t)(.*)$/g.exec(line)
                fullClipboardArray.push({id, text})
                updateFilteredItems()
            }
        }
    }
    
    readonly property color colorBg: "#121212"
    readonly property color colorSurface: "#1e1e1e"
    readonly property color colorAccent: "#3d5afe"
    readonly property color colorText: "#ffffff"
    readonly property color colorTextDim: "#b0b0b0"
    readonly property int borderRadius: 12

    Popup {
        id: popup
        x: initialX
        y: initialY
        implicitWidth: popUpWidth
        implicitHeight: popUpHeight
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: false
        modal: false
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

        onClosed: {
            Qt.quit()
        }

        contentItem: Item {
            id: contentContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Clipboard History"
                        color: colorText
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                
                    AbstractButton {
                        id: clearAllBtn
                        onPressed: clearAll()
                        Keys.onReturnPressed: clearAll()
                        implicitWidth: 70
                        implicitHeight: 24

                        background: Rectangle {
                            color: clearAllBtn.hovered || clearAllBtn.activeFocus ? Qt.rgba(1,1,1,0.1) : "transparent"
                            radius: 6
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        contentItem: Text {
                            text: "Clear All"
                            color: clearAllBtn.hovered || clearAllBtn.activeFocus ? colorText : colorTextDim
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search history..."
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

                    // Search icon
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: searchInput.activeFocus ? colorAccent : colorTextDim
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Keys.onTabPressed: {
                        if(clipboardHistory.count > 0) {
                            historyView.currentItem.itemRoot.forceActiveFocus()
                        } else {
                            clearAllBtn.forceActiveFocus()
                        }
                    }

                    onTextEdited: {
                        filterSelection(text)
                        isSearching = true
                    }
                }

                ScrollView {
                    id: scroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AsNeeded
                        active: true
                        background: Rectangle {
                            color: "transparent"
                            width: 6
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: vbar.hovered ? colorAccent : Qt.rgba(1,1,1,0.2)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    ListView {
                        id: historyView
                        model: clipboardHistory
                        cacheBuffer: 10
                        spacing: 8
                        focus: true
                        clip: true
                        
                        keyNavigationEnabled: true
                        keyNavigationWraps: false

                        Keys.onPressed: (event) => {
                            switch (event.key) {
                                case Qt.Key_Right:
                                    incrementCurrentIndex()
                                    if (currentItem) {
                                        currentItem.itemRoot.forceActiveFocus()
                                    }
                                    event.accepted = true
                                    break
                                case Qt.Key_Left:
                                    decrementCurrentIndex()
                                    if (currentItem) {
                                        currentItem.itemRoot.forceActiveFocus()
                                    }
                                    event.accepted = true
                                    break
                            }
                        }

                        delegate: ClipboardItem {
                            width: historyView.width - (scroll.ScrollBar.vertical.visible ? 10 : 0)
                            Keys.onReturnPressed: pasteSelected(model)
                            
                            onActiveIndexChanged: {
                                if (activeIndex) {
                                    itemRoot.forceActiveFocus()
                                }
                            }
                            onFocusChanged: {
                                if (focus) {
                                    historyView.positionViewAtIndex(index, ListView.Contain)
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    function clearAll() {
        Quickshell.execDetached(["bash", "-c", "cliphist wipe"])
        clipboardHistory.clear()
        fullClipboardArray = []
    }
    
    function removeSelected(model, index) {
        Quickshell.execDetached(["bash", "-c", `printf '${model.id}' | cliphist delete`])
        fullClipboardArray = fullClipboardArray.filter(({ id }) => id !== model.id)
        clipboardHistory.remove(index)
    }
    
    function pasteSelected(model) {
        Quickshell.execDetached(["bash", "-c", `printf '${model.id}' | cliphist decode | wl-copy && hyprctl dispatch sendshortcut CTRL, V, activewindow`])
        Qt.quit()
    }

    function updateFilteredItems() {
        clipboardHistory.clear()
        
        if (filterQuery.trim() === "") {
            for (const item of fullClipboardArray) {
                clipboardHistory.append(item)
            }
        } else {
            const filtered = fullClipboardArray.filter(item => {
                if([">img", ">image"].includes(filterQuery)) {
                    return checkIsImage(item.text)
                } else {
                    return item.text.toLowerCase().includes(filterQuery.toLowerCase())
                }
            })
            for (const item of filtered) {
                clipboardHistory.append(item)
            }
        }
    }

    function checkIsImage(preview) {
        if (!preview) return false
        const imagePattern = /^\[\[ binary data .+ (png|jpg|jpeg|gif|bmp|svg|webp|tiff) \d+x\d+ \]\]$/i
        return imagePattern.test(preview.trim())
    }

    function filterSelection(query) {
        filterQuery = query
        filterTimer.restart()
    }
}