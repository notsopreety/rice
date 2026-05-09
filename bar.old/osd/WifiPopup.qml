import QtQuick
import Quickshell
import "../theme"

PanelWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 320
    implicitHeight: 560
    color: "transparent"
    focusable: true
    exclusiveZone: 0

    property int xPos: 0
    property int yPos: 0
    property var screenObj: null
    screen: screenObj
    anchors.top: true
    anchors.left: true
    margins.top: 0
    margins.left: xPos

    property string animState: "closed"
    property string viewState: "list"
    property string targetSSID: ""
    property string targetSecurity: ""
    property string passwordText: ""
    property string activeMenuSSID: ""

    Connections {
        target: SessionState
        function onWifiPopupVisibleChanged() {
            if (SessionState.wifiPopupVisible) {
                viewState = "list"
                passwordText = ""
                activeMenuSSID = ""
                animState = "open"
                NetworkState.rescan()
            } else {
                animState = "closing"
            }
        }
    }

    function sigIcon(s) {
        if (s >= 80) return "󰤨"
        if (s >= 60) return "󰤥"
        if (s >= 40) return "󰤢"
        if (s >= 20) return "󰤟"
        return "󰤯"
    }

    function sigLabel(s) {
        if (s >= 80) return "Excellent"
        if (s >= 60) return "Good"
        if (s >= 40) return "Fair"
        if (s >= 20) return "Weak"
        return "Very Weak"
    }

    function isSecured(sec) { return sec !== "" && sec !== "--" }

    function handleNetworkClick(ssid, security, known) {
        if (known || !isSecured(security)) {
            NetworkState.connect(ssid)
        } else {
            targetSSID = ssid
            targetSecurity = security
            passwordText = ""
            viewState = "password"
        }
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: Math.min(mainCol.implicitHeight + 24, 520)
        radius: 14
        clip: true
        color: Colors.grey900
        border.color: NetworkState.wifiEnabled ? Colors.purple200 : Colors.grey700
        border.width: 2

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
            id: mainCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 6
            visible: root.viewState === "list"

            // ── 1. POWER HEADER ──
            Rectangle {
                width: parent.width
                height: 52
                radius: 10
                color: NetworkState.wifiEnabled ? Colors.purple200 : Colors.grey800
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Text {
                        text: NetworkState.wifiEnabled ? "󰤨" : "󰤭"
                        font.pixelSize: 22
                        color: NetworkState.wifiEnabled ? Colors.grey900 : Colors.grey300
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: NetworkState.wifiEnabled ? "Wi-Fi" : "Wi-Fi Off"
                            font.pixelSize: 14
                            font.bold: true
                            color: NetworkState.wifiEnabled ? Colors.grey900 : Colors.grey200
                        }
                        Text {
                            visible: NetworkState.wifiEnabled
                            text: NetworkState.activeSSID !== "" ? "Connected to " + NetworkState.activeSSID : "Not connected"
                            font.pixelSize: 10
                            color: Colors.grey900
                            opacity: 0.7
                        }
                    }
                }
                
                // Toggle switch
                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: NetworkState.wifiEnabled ? Colors.grey900 : Colors.grey700
                    
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: NetworkState.wifiEnabled ? 24 : 3
                        color: NetworkState.wifiEnabled ? Colors.purple200 : Colors.grey400
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: NetworkState.toggleWifi()
                    }
                }
            }

            // ── 2. ACTIVE CONNECTION ──
            Rectangle {
                visible: NetworkState.wifiEnabled && NetworkState.activeSSID !== ""
                width: parent.width
                height: visible ? 64 : 0
                radius: 10
                color: Colors.grey800
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 10
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(Colors.purple200.r, Colors.purple200.g, Colors.purple200.b, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: sigIcon(NetworkState.activeSignal)
                            font.pixelSize: 20
                            color: Colors.purple200
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 88
                        Text {
                            text: NetworkState.activeSSID
                            font.pixelSize: 13
                            font.bold: true
                            color: Colors.grey200
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Row {
                            spacing: 8
                            Text { text: sigLabel(NetworkState.activeSignal); font.pixelSize: 9; color: Colors.purple200 }
                            Text { text: "•"; font.pixelSize: 9; color: Colors.grey600 }
                            Text { text: NetworkState.activeSignal + "%"; font.pixelSize: 9; color: Colors.grey500 }
                        }
                    }
                    MouseArea {
                        width: 24
                        height: parent.height
                        onClicked: activeMenuSSID = activeMenuSSID === NetworkState.activeSSID ? "" : NetworkState.activeSSID
                        Text {
                            anchors.centerIn: parent
                            text: "󰇙"
                            font.pixelSize: 16
                            color: Colors.grey400
                        }
                    }
                }
            }

            // Active menu
            Rectangle {
                width: parent.width
                radius: 8
                clip: true
                height: activeMenuSSID === NetworkState.activeSSID ? 76 : 0
                visible: height > 0
                color: Qt.lighter(Colors.grey900, 1.15)
                border.color: Colors.grey700
                border.width: 1
                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    spacing: 2
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
                            Text { text: "󰤭"; font.pixelSize: 14; color: Colors.red400 }
                            Text { text: "Disconnect"; font.pixelSize: 11; font.bold: true; color: Colors.grey200 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(["nmcli", "con", "down", NetworkState.activeSSID])
                                activeMenuSSID = ""
                            }
                        }
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
                            Text { text: "Forget network"; font.pixelSize: 11; font.bold: true; color: Colors.grey200 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(["nmcli", "con", "delete", NetworkState.activeSSID])
                                activeMenuSSID = ""
                            }
                        }
                    }
                }
            }

            // ── 3. SCAN BUTTON ──
            Rectangle {
                visible: NetworkState.wifiEnabled
                width: parent.width
                height: 36
                radius: 8
                color: NetworkState.isScanning ? Colors.deepPurple200 : Colors.grey800
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰑐"
                        font.pixelSize: 16
                        color: NetworkState.isScanning ? Colors.grey900 : Colors.grey200
                        RotationAnimation on rotation {
                            running: NetworkState.isScanning
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                        }
                    }
                    Text {
                        text: NetworkState.isScanning ? "Searching..." : "Scan for networks"
                        font.pixelSize: 12
                        font.bold: true
                        color: NetworkState.isScanning ? Colors.grey900 : Colors.grey200
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: NetworkState.rescan() }
            }

            // ── 4. SAVED NETWORKS ──
            Column {
                visible: NetworkState.wifiEnabled
                width: parent.width
                spacing: 4
                Text {
                    text: "SAVED NETWORKS"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.purple200
                    leftPadding: 4
                }
                Repeater {
                    model: NetworkState.networks
                    delegate: Rectangle {
                        required property var modelData
                        visible: modelData.known && modelData.ssid !== NetworkState.activeSSID
                        width: parent.width
                        height: visible ? 44 : 0
                        radius: 8
                        color: knMouse.containsMouse ? Colors.grey700 : Colors.grey800
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(Colors.purple200.r, Colors.purple200.g, Colors.purple200.b, 0.12)
                                Text { anchors.centerIn: parent; text: sigIcon(modelData.signal); font.pixelSize: 16; color: Colors.purple200 }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 56
                                Text { text: modelData.ssid; font.pixelSize: 12; font.bold: true; color: Colors.grey200; elide: Text.ElideRight; width: parent.width }
                                Text { text: "Saved • " + sigLabel(modelData.signal); font.pixelSize: 9; color: Colors.grey500 }
                            }
                        }
                        MouseArea {
                            id: knMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.handleNetworkClick(modelData.ssid, modelData.security, true)
                        }
                    }
                }
            }

            // ── 5. AVAILABLE NETWORKS ──
            Column {
                visible: NetworkState.wifiEnabled
                width: parent.width
                spacing: 4
                Text {
                    text: "AVAILABLE"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.teal200
                    leftPadding: 4
                }
                Flickable {
                    width: parent.width
                    height: Math.min(availNetCol.implicitHeight, 200)
                    contentHeight: availNetCol.implicitHeight
                    clip: true
                    interactive: contentHeight > height
                    Column {
                        id: availNetCol
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: NetworkState.networks
                            delegate: Rectangle {
                                required property var modelData
                                visible: !modelData.known
                                width: availNetCol.width
                                height: visible ? 44 : 0
                                radius: 8
                                color: avMouse.containsMouse ? Colors.grey700 : Colors.grey800
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(Colors.teal200.r, Colors.teal200.g, Colors.teal200.b, 0.12)
                                        Text { anchors.centerIn: parent; text: sigIcon(modelData.signal); font.pixelSize: 16; color: Colors.teal200 }
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 56
                                        Text { text: modelData.ssid; font.pixelSize: 12; font.bold: true; color: Colors.grey200; elide: Text.ElideRight; width: parent.width }
                                        Row {
                                            spacing: 6
                                            Text { text: sigLabel(modelData.signal); font.pixelSize: 9; color: Colors.grey500 }
                                            Text { visible: isSecured(modelData.security); text: "• 󰌾"; font.pixelSize: 9; color: Colors.grey500 }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: avMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.handleNetworkClick(modelData.ssid, modelData.security, false)
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Rectangle { visible: NetworkState.wifiEnabled; width: parent.width; height: 1; color: Colors.grey800 }
            Rectangle {
                visible: NetworkState.wifiEnabled
                width: parent.width
                height: 34
                radius: 8
                color: ftMouse.containsMouse ? Colors.grey700 : Colors.grey800
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰒓"; font.pixelSize: 16; color: Colors.grey400 }
                    Text { text: "Network settings..."; font.pixelSize: 12; font.bold: true; color: Colors.grey400 }
                }
                MouseArea {
                    id: ftMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "--title=nmtui", "-e", "nmtui"])
                        SessionState.wifiPopupVisible = false
                    }
                }
            }
        }

        // ── PASSWORD VIEW ──
        Column {
            id: pwView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 8
            visible: root.viewState === "password"
            opacity: visible ? 1.0 : 0.0
            Rectangle {
                width: parent.width
                height: 36
                radius: 8
                color: Colors.grey800
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text { text: "󰁍"; font.pixelSize: 16; color: Colors.grey200 }
                    Text { text: "Back"; font.pixelSize: 12; font.bold: true; color: Colors.grey200 }
                }
                MouseArea { anchors.fill: parent; onClicked: root.viewState = "list" }
            }
            Rectangle {
                width: parent.width
                height: 48
                radius: 10
                color: Colors.purple200
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text { text: "󰤨"; font.pixelSize: 20; color: Colors.grey900 }
                    Column {
                        Text { text: root.targetSSID; font.pixelSize: 13; font.bold: true; color: Colors.grey900 }
                        Text { text: "󰌾 " + root.targetSecurity; font.pixelSize: 9; color: Colors.grey900; opacity: 0.7 }
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: pwInput.activeFocus ? Qt.lighter(Colors.grey800, 1.15) : Colors.grey800
                border.color: NetworkState.connectError !== "" ? Colors.red400 : (pwInput.activeFocus ? Colors.purple200 : "transparent")
                border.width: pwInput.activeFocus || NetworkState.connectError !== "" ? 1 : 0
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text { text: "󰌾"; font.pixelSize: 16; color: Colors.grey400 }
                    TextInput {
                        id: pwInput
                        width: parent.width - 50
                        font.pixelSize: 13
                        font.bold: true
                        color: Colors.grey200
                        echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                        clip: true
                        text: root.passwordText
                        onTextChanged: { root.passwordText = text; NetworkState.connectError = "" }
                        onAccepted: if (root.passwordText.length > 0) { NetworkState.connect(root.targetSSID, root.passwordText); root.viewState = "list" }
                    }
                    Text {
                        text: showPw.checked ? "󰈈" : "󰈉"
                        font.pixelSize: 16
                        color: Colors.grey400
                        MouseArea { anchors.fill: parent; onClicked: showPw.checked = !showPw.checked }
                    }
                }
                MouseArea { anchors.fill: parent; z: -1; onClicked: pwInput.forceActiveFocus() }
                Text {
                    visible: pwInput.text === "" && !pwInput.activeFocus
                    anchors.left: parent.left
                    anchors.leftMargin: 37
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter password"
                    font.pixelSize: 13
                    color: Colors.grey600
                }
            }
            Item { id: showPw; property bool checked: false; visible: false }
            Text {
                visible: NetworkState.connectError !== ""
                text: NetworkState.connectError
                font.pixelSize: 11
                font.bold: true
                color: Colors.red400
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: root.passwordText.length > 0 ? Colors.purple200 : Colors.grey800
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰤨"; font.pixelSize: 16; color: root.passwordText.length > 0 ? Colors.grey900 : Colors.grey500 }
                    Text { text: "Connect"; font.pixelSize: 13; font.bold: true; color: root.passwordText.length > 0 ? Colors.grey900 : Colors.grey500 }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.passwordText.length > 0) { NetworkState.connect(root.targetSSID, root.passwordText); root.viewState = "list" }
                }
            }
        }
    }
    onViewStateChanged: { if (viewState === "password") pwInput.forceActiveFocus() }
}
