import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: main
    implicitHeight: Screen.height
    implicitWidth: Screen.width
    color: "transparent"

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 1

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        Quickshell.execDetached(["bash", Quickshell.shellPath("cache.sh"), Quickshell.shellDir])
    }

    // ============================================
    // CONFIGURATION
    // ============================================
    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures: 7
            property string border_color: "#C27B63"
            property int cache_batch_size: 20
        }
    }

    // ============================================
    // CURRENT WALLPAPER DETECTION
    // ============================================
    property string currentWallpaperPath: ""
    property bool initialIndexSet: false

    Process {
        id: readCurrentWallpaper
        command: ["cat", "/home/sawmer/.cache/awww-wal/current"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                main.currentWallpaperPath = data.trim()
                main.setInitialIndex()
            }
        }
    }

    function setInitialIndex() {
        if (initialIndexSet || folderModel.count === 0 || !currentWallpaperPath) return

        // Extract just the filename
        let parts = currentWallpaperPath.split("/")
        let targetName = parts[parts.length - 1]

        for (let i = 0; i < folderModel.count; i++) {
            let fn = folderModel.get(i, "fileName")
            if (fn === targetName) {
                carousel.currentIndex = i
                selectedIndex = i
                initialIndexSet = true
                return
            }
        }
        initialIndexSet = true
    }

    // ============================================
    // WALLPAPER MODEL
    // ============================================
    FolderListModel {
        id: folderModel
        folder: "file://" + configs.wallpaper_path
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name

        onCountChanged: main.setInitialIndex()
    }

    // ============================================
    // STATE & PROPERTIES
    // ============================================
    property int selectedIndex: 0

    function activateCurrent() {
        const path = folderModel.get(selectedIndex, "filePath")
        if (path) {
            Quickshell.execDetached(["/home/sawmer/.config/scripts/wall.sh", "-i=" + path])
        }
        Qt.quit()
    }

    function randomWallpaper() {
        Quickshell.execDetached(["/home/sawmer/.config/scripts/wall.sh", "-i=rand"])
        Qt.quit()
    }

    // ============================================
    // BACKGROUND DIM - click to close
    // ============================================
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }

    // ============================================
    // HORIZONTAL SPOTLIGHT SLIDER
    // ============================================
    PathView {
        id: carousel
        anchors.fill: parent
        focus: true
        model: folderModel

        // Flat horizontal path - spotlight style
        path: Path {
            startX: 0
            startY: carousel.height / 2

            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }

            PathLine {
                x: carousel.width / 2
                y: carousel.height / 2
            }

            PathAttribute { name: "z"; value: 100 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }

            PathLine {
                x: carousel.width
                y: carousel.height / 2
            }

            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
        }

        pathItemCount: configs.number_of_pictures

        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

        currentIndex: main.selectedIndex
        onCurrentIndexChanged: main.selectedIndex = currentIndex

        snapMode: PathView.SnapToItem
        flickDeceleration: 1200
        maximumFlickVelocity: 800

        // ============================================
        // DELEGATE - MANGA CARD
        // ============================================
        delegate: Item {
            id: delegate
            width: 220
            height: 330

            property real itemScale: PathView.itemScale !== undefined ? PathView.itemScale : 0.65
            property real itemZ: PathView.z !== undefined ? PathView.z : 0
            property real itemOpacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 0.35
            property bool isCurrent: PathView.isCurrentItem

            z: itemZ
            opacity: itemOpacity
            scale: itemScale

            // ============================================
            // SHADOW
            // ============================================
            Rectangle {
                visible: isCurrent
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                radius: 12
                border.width: 1
                border.color: Qt.rgba(
                    parseInt(configs.border_color.substr(1,2), 16) / 255,
                    parseInt(configs.border_color.substr(3,2), 16) / 255,
                    parseInt(configs.border_color.substr(5,2), 16) / 255,
                    0.3
                )
            }

            // ============================================
            // IMAGE CONTAINER
            // ============================================
            Rectangle {
                id: imageContainer
                anchors.fill: parent
                color: "#1a1a2e"
                radius: 8
                border.width: isCurrent ? 2 : 0
                border.color: configs.border_color
                clip: true

                Image {
                    id: img
                    anchors.fill: parent
                    anchors.margins: isCurrent ? 2 : 0
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true

                    source: "file://" + configs.cache_path + fileName

                    sourceSize.width: 400
                    sourceSize.height: 600

                    Rectangle {
                        visible: img.status !== Image.Ready
                        anchors.fill: parent
                        color: "#252545"

                        Text {
                            anchors.centerIn: parent
                            text: "Loading..."
                            color: "#888888"
                            font.pixelSize: 12
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Error) {
                            retryTimer.start()
                        }
                    }

                    Timer {
                        id: retryTimer
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            let s = img.source
                            img.source = ""
                            img.source = s
                        }
                    }
                }
            }

            // ============================================
            // FILENAME LABEL (current only)
            // ============================================
            Text {
                visible: isCurrent
                anchors.top: imageContainer.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: imageContainer.horizontalCenter
                text: fileName.replace(/\.[^/.]+$/, "")
                color: "#cccccc"
                font.pixelSize: 12
                font.family: "Inter"
            }

            // ============================================
            // CLICK TO SELECT
            // ============================================
            MouseArea {
                anchors.fill: imageContainer

                onClicked: {
                    if (isCurrent) {
                        main.activateCurrent()
                    } else {
                        carousel.currentIndex = index
                        main.selectedIndex = index
                    }
                }
            }
        }

        // ============================================
        // KEYBOARD CONTROLS
        // ============================================
        Keys.onPressed: function(event) {
            switch (event.key) {
                case Qt.Key_Right:
                case Qt.Key_L:
                case Qt.Key_D:
                    carousel.incrementCurrentIndex()
                    break

                case Qt.Key_Left:
                case Qt.Key_H:
                case Qt.Key_A:
                    carousel.decrementCurrentIndex()
                    break

                case Qt.Key_Space:
                case Qt.Key_Return:
                    main.activateCurrent()
                    break

                case Qt.Key_Escape:
                    Qt.quit()
                    break

                default:
                    return
            }
            event.accepted = true
        }

        // Mouse wheel scrolling (both axes, speed-limited)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton

            property bool wheelLocked: false

            Timer {
                id: wheelCooldown
                interval: 80
                onTriggered: parent.wheelLocked = false
            }

            onWheel: function(wheel) {
                if (wheelLocked) { wheel.accepted = true; return }
                let dy = wheel.angleDelta.y
                let dx = wheel.angleDelta.x
                let delta = Math.abs(dy) > Math.abs(dx) ? dy : dx
                if (delta < 0) {
                    carousel.incrementCurrentIndex()
                } else if (delta > 0) {
                    carousel.decrementCurrentIndex()
                }
                wheelLocked = true
                wheelCooldown.restart()
                wheel.accepted = true
            }
        }
    }

    // ============================================
    // COUNTER (above spotlight)
    // ============================================
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 200
        text: (main.selectedIndex + 1) + "/" + folderModel.count
        color: "#888888"
        font.pixelSize: 13
        font.family: "Inter"
    }

    // ============================================
    // BOTTOM CONTROLS
    // ============================================
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + 210
        spacing: 10

        // Previous button
        Rectangle {
            width: 38
            height: 38
            radius: 4
            color: prevMouse.pressed ? "#1a1a1a" : prevMouse.containsMouse ? "#2a2a2a" : "#1e1e1e"
            border.width: 1
            border.color: prevMouse.containsMouse ? configs.border_color : "#383838"

            Text {
                anchors.centerIn: parent
                text: "\u276E"
                color: prevMouse.containsMouse ? "#dddddd" : "#999999"
                font.pixelSize: 14
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: carousel.decrementCurrentIndex()
            }
        }

        // Random button
        Rectangle {
            width: 90
            height: 38
            radius: 4
            color: randMouse.pressed ? "#1a1a1a" : randMouse.containsMouse ? "#2a2a2a" : "#1e1e1e"
            border.width: 1
            border.color: randMouse.containsMouse ? configs.border_color : "#383838"

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\u2736"
                    color: randMouse.containsMouse ? configs.border_color : "#777777"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Random"
                    color: randMouse.containsMouse ? "#dddddd" : "#999999"
                    font.pixelSize: 12
                    font.family: "Inter"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: randMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: main.randomWallpaper()
            }
        }

        // Next button
        Rectangle {
            width: 38
            height: 38
            radius: 4
            color: nextMouse.pressed ? "#1a1a1a" : nextMouse.containsMouse ? "#2a2a2a" : "#1e1e1e"
            border.width: 1
            border.color: nextMouse.containsMouse ? configs.border_color : "#383838"

            Text {
                anchors.centerIn: parent
                text: "\u276F"
                color: nextMouse.containsMouse ? "#dddddd" : "#999999"
                font.pixelSize: 14
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: carousel.incrementCurrentIndex()
            }
        }
    }
}