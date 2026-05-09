import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../theme"

PopupWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 320
    implicitHeight: 600
    color: "transparent"

    property string animState: "closed"
    property string activeMenuDevice: ""

    Connections {
        target: SessionState
        function onBluetoothPopupVisibleChanged() {
            if (SessionState.bluetoothPopupVisible) {
                animState = "open"
                activeMenuDevice = ""
            } else {
                animState = "closing"
                activeMenuDevice = ""
            }
        }
    }

    readonly property bool btOn: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    readonly property bool scanning: btOn && Bluetooth.defaultAdapter.discovering

    function getDeviceIcon(dev) {
        var ic = dev.icon || ""
        if (ic.indexOf("headset") !== -1 || ic.indexOf("headphone") !== -1) return "󰋋"
        if (ic.indexOf("audio") !== -1 || ic.indexOf("speaker") !== -1) return "󰓃"
        if (ic.indexOf("mouse") !== -1 || ic.indexOf("input-gaming") !== -1) return "󰍽"
        if (ic.indexOf("keyboard") !== -1) return "󰌌"
        if (ic.indexOf("phone") !== -1) return "󰄜"
        if (ic.indexOf("display") !== -1 || ic.indexOf("video") !== -1) return "󰍹"
        if (ic.indexOf("computer") !== -1) return "󰟀"
        if (ic.indexOf("printer") !== -1) return "󰐪"
        if (ic.indexOf("camera") !== -1) return "󰄀"
        if (ic.indexOf("watch") !== -1) return "󰥔"
        return "󰂯"
    }

    function getDeviceType(dev) {
        var ic = dev.icon || ""
        if (ic.indexOf("headset") !== -1 || ic.indexOf("headphone") !== -1) return "Audio"
        if (ic.indexOf("audio") !== -1 || ic.indexOf("speaker") !== -1) return "Speaker"
        if (ic.indexOf("mouse") !== -1) return "Mouse"
        if (ic.indexOf("keyboard") !== -1) return "Keyboard"
        if (ic.indexOf("phone") !== -1) return "Phone"
        if (ic.indexOf("display") !== -1) return "Display"
        if (ic.indexOf("computer") !== -1) return "Computer"
        if (ic.indexOf("printer") !== -1) return "Printer"
        if (ic.indexOf("camera") !== -1) return "Camera"
        if (ic.indexOf("watch") !== -1) return "Watch"
        if (ic.indexOf("gaming") !== -1) return "Controller"
        return "Device"
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: Math.min(mainColumn.implicitHeight + 24, 520)
        radius: 14
        color: Colors.grey900
        border.color: btOn ? Colors.lightBlue200 : Colors.grey700
        border.width: 2
        clip: true

        Behavior on height { SmoothedAnimation { velocity: 900; easing.type: Easing.OutExpo } }
        y: 0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerRect; y: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerRect; y: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                from: "*"
                to: "open"
                SequentialAnimation {
                    PropertyAction { target: innerRect; property: "y"; value: -20 }
                    PropertyAction { target: innerRect; property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y"; to: 0; duration: 280; easing.type: Easing.OutExpo }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                from: "*"
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y"; to: -20; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        Column {
            id: mainColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 6

            // ── 1. POWER HEADER ──
            Rectangle {
                width: parent.width
                height: 52
                radius: 10
                color: btOn ? Colors.lightBlue200 : Colors.grey800

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Text {
                        text: btOn ? "󰂯" : "󰂲"
                        font.pixelSize: 22
                        color: btOn ? Colors.grey900 : Colors.grey300
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: btOn ? "Bluetooth" : "Bluetooth Off"
                            font.pixelSize: 14
                            font.bold: true
                            color: btOn ? Colors.grey900 : Colors.grey200
                        }
                        Text {
                            visible: btOn
                            text: {
                                var count = 0
                                for (var i = 0; i < Bluetooth.devices.count; i++) {
                                    if (Bluetooth.devices.get(i).connected) count++
                                }
                                return count > 0 ? count + " connected" : "No devices connected"
                            }
                            font.pixelSize: 10
                            color: Colors.grey900
                            opacity: 0.7
                        }
                    }
                }

                // Dedicated Toggle Button
                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: btOn ? Colors.grey900 : Colors.grey700
                    
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: btOn ? 24 : 3
                        color: btOn ? Colors.lightBlue200 : Colors.grey400
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (btOn) {
                                Quickshell.execDetached(["bluetoothctl", "power", "off"])
                            } else {
                                Quickshell.execDetached(["rfkill", "unblock", "bluetooth"])
                                Quickshell.execDetached(["bluetoothctl", "power", "on"])
                            }
                        }
                    }
                }
            }

            // ── 2. SCAN BUTTON ──
            Rectangle {
                visible: btOn
                width: parent.width
                height: 36
                radius: 8
                color: scanning ? Colors.teal200 : Colors.grey800

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰑐"
                        font.pixelSize: 16
                        color: scanning ? Colors.grey900 : Colors.grey200
                        RotationAnimation on rotation {
                            running: scanning
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                        }
                    }
                    Text {
                        text: scanning ? "Searching..." : "Scan for devices"
                        font.pixelSize: 12
                        font.bold: true
                        color: scanning ? Colors.grey900 : Colors.grey200
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
                }
            }

            // ── 3. MY DEVICES ──
            Column {
                visible: btOn
                width: parent.width
                spacing: 4
                Text { text: "MY DEVICES"; font.pixelSize: 10; font.bold: true; color: Colors.lightBlue200; leftPadding: 4 }
                Repeater {
                    model: Bluetooth.devices
                    delegate: Column {
                        required property var modelData
                        visible: modelData.paired
                        width: parent.width
                        Rectangle {
                            width: parent.width
                            height: visible ? 48 : 0
                            radius: 8
                            color: modelData.connected ? Colors.lightBlue200 : Colors.grey800
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 10
                                Text {
                                    text: getDeviceIcon(modelData)
                                    font.pixelSize: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.connected ? Colors.grey900 : Colors.grey200
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 60
                                    Text {
                                        text: modelData.name || "Unknown Device"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: modelData.connected ? Colors.grey900 : Colors.grey200
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: modelData.connected ? (modelData.batteryAvailable ? "Connected • " + modelData.battery + "%" : "Connected") : getDeviceType(modelData)
                                        font.pixelSize: 9
                                        color: modelData.connected ? Colors.grey900 : Colors.grey500
                                    }
                                }
                                MouseArea {
                                    width: 24
                                    height: parent.height
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰇙"
                                        font.pixelSize: 16
                                        color: modelData.connected ? Colors.grey900 : Colors.grey400
                                    }
                                    onClicked: root.activeMenuDevice = root.activeMenuDevice === modelData.address ? "" : modelData.address
                                }
                            }
                            MouseArea { anchors.fill: parent; z: -1; onClicked: modelData.connected = !modelData.connected }
                        }
                        Rectangle {
                            width: parent.width
                            radius: 8
                            height: root.activeMenuDevice === modelData.address ? menuCol.implicitHeight + 12 : 0
                            visible: height > 0
                            clip: true
                            color: Colors.grey800
                            border.color: Colors.grey700
                            border.width: 1
                            Column {
                                id: menuCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                spacing: 4
                                Rectangle {
                                    width: parent.width
                                    height: 32
                                    radius: 6
                                    color: "transparent"
                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Text { text: modelData.connected ? "󰤭" : "󰤨"; font.pixelSize: 14; color: Colors.grey200 }
                                        Text { text: modelData.connected ? "Disconnect" : "Connect"; font.pixelSize: 11; font.bold: true; color: Colors.grey200 }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: { modelData.connected = !modelData.connected; root.activeMenuDevice = "" } }
                                }
                                Rectangle {
                                    width: parent.width
                                    height: 32
                                    radius: 6
                                    color: "transparent"
                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Text { text: "󰆴"; font.pixelSize: 14; color: Colors.red400 }
                                        Text { text: "Unpair"; font.pixelSize: 11; font.bold: true; color: Colors.red400 }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: { modelData.paired = false; root.activeMenuDevice = "" } }
                                }
                            }
                        }
                    }
                }
            }

            // ── 4. AVAILABLE DEVICES ──
            Column {
                visible: btOn && scanning
                width: parent.width
                spacing: 4
                Text { text: "AVAILABLE"; font.pixelSize: 10; font.bold: true; color: Colors.teal200; leftPadding: 4 }
                Repeater {
                    model: Bluetooth.devices
                    delegate: Rectangle {
                        required property var modelData
                        visible: !modelData.paired && modelData.name.trim() !== ""
                        width: parent.width
                        height: visible ? 40 : 0
                        radius: 8
                        color: modelData.pairing ? Colors.yellow600 : Colors.grey800
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            Text { text: getDeviceIcon(modelData); font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter; color: modelData.pairing ? Colors.grey900 : Colors.grey200 }
                            Text { text: modelData.name; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: modelData.pairing ? Colors.grey900 : Colors.grey200; elide: Text.ElideRight; width: parent.width - 40 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: if (!modelData.pairing) modelData.pair() }
                    }
                }
            }

            // ── 5. FOOTER ──
            Rectangle {
                visible: btOn
                width: parent.width
                height: 34
                radius: 8
                color: Colors.grey800
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰇄"; font.pixelSize: 16; color: Colors.grey400 }
                    Text { text: "More Settings"; font.pixelSize: 12; font.bold: true; color: Colors.grey400 }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "--title=bluetoothctl", "-e", "bluetoothctl"])
                        SessionState.bluetoothPopupVisible = false
                    }
                }
            }
        }
    }
}
