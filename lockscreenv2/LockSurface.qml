import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Io

Rectangle {
	id: root
	required property LockContext context
	readonly property ColorGroup colors: Window.active ? palette.active : palette.inactive

	// Semi-transparent background
	color: "transparent"

	// Wallpaper image
	Image {
		id: wallpaper
		anchors.fill: parent
		source: "/home/sawmer/.cache/awww-wal/wall.jpg"
		fillMode: Image.PreserveAspectCrop
		visible: false
	}

	// Blur effect on wallpaper
	FastBlur {
		anchors.fill: parent
		source: wallpaperSource
		radius: 30
	}

	// Source for blur
	ShaderEffectSource {
		id: wallpaperSource
		sourceItem: wallpaper
		visible: false
	}

	// Semi-transparent overlay for readability
	Rectangle {
		anchors.fill: parent
		color: Qt.rgba(0, 0, 0, 0.3)
	}

	Button {
		text: "Its not working, let me out"
		onClicked: context.unlocked();
		
		background: Rectangle {
			color: Qt.rgba(0.2, 0.2, 0.3, 0.5)
			border.color: Qt.rgba(0.5, 0.5, 0.7, 0.3)
			border.width: 1
			radius: 8
		}
		
		contentItem: Text {
			text: parent.text
			color: "#ffffff"
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
		}
	}

	ColumnLayout {
		id: clockContainer
		property var date: new Date()

		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			topMargin: 120
		}

		// ============================================
		// CLOCK CONFIGURATION - Customize these values
		// ============================================
		// Global settings
		property string clockFontFamily: "Blanka"
		property int containerSpacing: 12

		// Day settings
		property int dayFontSize: 56
		property double dayOpacity: 1.0
		property int dayLetterSpacing: 20
		property int dayTopMargin: 0

		// Date settings
		property int dateFontSize: 20
		property double dateOpacity: 0.9
		property int dateLetterSpacing: 2
		property int dateTopMargin: 8

		// Time settings
		property int timeFontSize: 16
		property double timeOpacity: 0.8
		property int timeLetterSpacing: 1
		property int timeTopMargin: 12
		// ============================================

		spacing: containerSpacing

		// updates the clock every second
		Timer {
			running: true
			repeat: true
			interval: 1000
			onTriggered: clockContainer.date = new Date();
		}

		// Day name - Large futuristic style
		Label {
			renderType: Text.NativeRendering
			font.pointSize: clockContainer.dayFontSize
			font.family: clockContainer.clockFontFamily
			font.weight: Font.Bold
			font.letterSpacing: clockContainer.dayLetterSpacing
			color: "#ffffff"
			Layout.alignment: Qt.AlignHCenter
			Layout.topMargin: clockContainer.dayTopMargin
			opacity: clockContainer.dayOpacity
			style: Text.Outline
			styleColor: Qt.rgba(0, 0, 0, 0.3)

			text: {
				const days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
				return days[clockContainer.date.getDay()];
			}
		}

		// Date - Medium size
		Label {
			renderType: Text.NativeRendering
			font.pointSize: clockContainer.dateFontSize
			font.family: clockContainer.clockFontFamily
			font.weight: Font.Normal
			font.letterSpacing: clockContainer.dateLetterSpacing
			color: "#ffffff"
			Layout.alignment: Qt.AlignHCenter
			Layout.topMargin: clockContainer.dateTopMargin
			opacity: clockContainer.dateOpacity

			text: {
				const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
								'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
				const month = months[clockContainer.date.getMonth()];
				const day = clockContainer.date.getDate();
				const year = clockContainer.date.getFullYear();
				return `${month} ${day}, ${year}`;
			}
		}

		// Time - Small with decorative dashes
		Label {
			renderType: Text.NativeRendering
			font.pointSize: clockContainer.timeFontSize
			font.family: clockContainer.clockFontFamily
			font.weight: Font.Normal
			font.letterSpacing: clockContainer.timeLetterSpacing
			color: "#ffffff"
			Layout.alignment: Qt.AlignHCenter
			Layout.topMargin: clockContainer.timeTopMargin
			opacity: clockContainer.timeOpacity

			text: {
				let hours = clockContainer.date.getHours();
				const minutes = clockContainer.date.getMinutes().toString().padStart(2, '0');
				const ampm = hours >= 12 ? 'PM' : 'AM';
				hours = hours % 12;
				hours = hours ? hours : 12;
				return `- ${hours}:${minutes} ${ampm} -`;
			}
		}
	}

	// ============================================
	// STATUS BAR - Top of screen
	// ============================================
	RowLayout {
		id: statusBar
		anchors {
			top: parent.top
			topMargin: 20
			horizontalCenter: parent.horizontalCenter
		}
		spacing: 12

		// Battery
		Rectangle {
			id: batteryPill
			property var battery: UPower.displayDevice
			property bool hasBattery: battery && battery.ready
			property int pct: hasBattery ? Math.round(battery.percentage * 100) : 0
			property bool charging: hasBattery && (
				battery.state === UPowerDeviceState.Charging ||
				battery.state === UPowerDeviceState.FullyCharged
			)

			width: batteryLabel.implicitWidth + 24
			height: 36
			radius: 8
			color: Qt.rgba(0.18, 0.18, 0.19, 0.9)
			border.color: Qt.rgba(0.3, 0.3, 0.35, 0.2)
			border.width: 1

			Label {
				id: batteryLabel
				anchors.centerIn: parent
				font.family: "JetBrainsMono Nerd Font"
				font.pointSize: 12
				color: "#E6E1E5"
				text: {
					if (!parent.hasBattery) return "󰚥 AC"
					var sym = ""
					if (parent.charging) {
						if (parent.pct >= 90) sym = "󰂅"
						else if (parent.pct >= 80) sym = "󰂋"
						else if (parent.pct >= 70) sym = "󰂊"
						else if (parent.pct >= 60) sym = "󰢞"
						else if (parent.pct >= 50) sym = "󰂉"
						else if (parent.pct >= 40) sym = "󰢝"
						else if (parent.pct >= 30) sym = "󰂈"
						else if (parent.pct >= 20) sym = "󰂇"
						else if (parent.pct >= 10) sym = "󰂆"
						else sym = "󰢜"
					} else {
						if (parent.pct >= 90) sym = "󰁹"
						else if (parent.pct >= 80) sym = "󰂂"
						else if (parent.pct >= 70) sym = "󰂁"
						else if (parent.pct >= 60) sym = "󰂀"
						else if (parent.pct >= 50) sym = "󰁿"
						else if (parent.pct >= 40) sym = "󰁾"
						else if (parent.pct >= 30) sym = "󰁽"
						else if (parent.pct >= 20) sym = "󰁼"
						else if (parent.pct >= 10) sym = "󰁻"
						else sym = "󰁺"
					}
					return sym + " " + parent.pct + "%"
				}
			}
		}

		// WiFi
		Rectangle {
			id: wifiPill
			width: wifiLabel.implicitWidth + 24
			height: 36
			radius: 8
			color: Qt.rgba(0.18, 0.18, 0.19, 0.9)
			border.color: Qt.rgba(0.3, 0.3, 0.35, 0.2)
			border.width: 1

			property bool wifiEnabled: true
			property string wifiSSID: ""
			property int wifiSignal: 0
			property bool wifiConnected: false

			Label {
				id: wifiLabel
				anchors.centerIn: parent
				font.family: "JetBrainsMono Nerd Font"
				font.pointSize: 12
				color: "#E6E1E5"

				text: {
					if (!parent.wifiEnabled) return "󰤭 WiFi Off"
					if (!parent.wifiConnected) return "󰤯 Disconnected"
					
					var signal = parent.wifiSignal
					var icon = ""
					if (signal >= 80) icon = "󰤨"
					else if (signal >= 60) icon = "󰤥"
					else if (signal >= 40) icon = "󰤢"
					else if (signal >= 20) icon = "󰤟"
					else icon = "󰤯"
					
					var ssid = parent.wifiSSID || "Connected"
					return icon + " " + ssid
				}
			}

			// Check WiFi status periodically
			Timer {
				interval: 5000
				running: true
				repeat: true
				onTriggered: wifiCheckProc.running = true
			}

			Process {
				id: wifiCheckProc
				command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
				running: false
				stdout: SplitParser {
					onRead: function(line) {
						var parts = line.split(":")
						if (parts.length >= 3 && parts[0] === "yes") {
							parent.wifiConnected = true
							parent.wifiSSID = parts[1]
							parent.wifiSignal = parseInt(parts[2]) || 0
						}
					}
				}
				onRunningChanged: {
					if (!running) {
						// Reset if no active connection found
						if (parent.wifiSSID === "") parent.wifiConnected = false
					}
				}
			}

			// Check WiFi radio status
			Timer {
				interval: 10000
				running: true
				onTriggered: wifiRadioProc.running = true
			}

			Process {
				id: wifiRadioProc
				command: ["nmcli", "radio", "wifi"]
				running: false
				stdout: SplitParser {
					onRead: function(line) {
						parent.wifiEnabled = line.trim() === "enabled"
					}
				}
			}

			Component.onCompleted: {
				wifiCheckProc.running = true
				wifiRadioProc.running = true
			}
		}

		// Bluetooth
		Rectangle {
			id: bluetoothPill
			property var adapter: Bluetooth.defaultAdapter
			property var connectedDevices: Bluetooth.devices

			width: bluetoothLabel.implicitWidth + 24
			height: 36
			radius: 8
			color: Qt.rgba(0.18, 0.18, 0.19, 0.9)
			border.color: Qt.rgba(0.3, 0.3, 0.35, 0.2)
			border.width: 1

			Label {
				id: bluetoothLabel
				anchors.centerIn: parent
				font.family: "JetBrainsMono Nerd Font"
				font.pointSize: 12
				color: "#E6E1E5"
				text: {
					if (!parent.adapter || !parent.adapter.enabled) return "󰂲 Bluetooth Off"
					if (!parent.connectedDevices || !parent.connectedDevices.values) return "󰂯 On"
					var connected = parent.connectedDevices.values.filter(d => d.state === BluetoothDeviceState.Connected)
					if (connected.length === 0) return "󰂯 On"
					return "󰂱 " + connected[0].name.substring(0, 12)
				}
			}
		}
	}

	// ============================================
	// MEDIA PLAYER - Below clock
	// ============================================
	Rectangle {
		id: mediaPlayer
		property string playerStatus: ""
		property string trackTitle: ""
		property string trackArtist: ""
		property string playerName: ""
		property string artUrl: ""
		property real trackLength: 0
		property real currentPosition: 0
		property bool isActive: playerStatus === "Playing" || playerStatus === "Paused"

		anchors {
			horizontalCenter: parent.horizontalCenter
			top: clockContainer.bottom
			topMargin: isActive ? 30 : 0
		}

		width: isActive ? 440 : 0
		height: isActive ? 120 : 0
		radius: 16
		color: Qt.rgba(0.11, 0.11, 0.12, 0.95)
		border.color: Qt.rgba(0.3, 0.3, 0.35, 0.3)
		border.width: 1
		opacity: isActive ? 1 : 0
		visible: opacity > 0

		// Material elevation shadow
		Rectangle {
			anchors.fill: parent
			radius: parent.radius
			color: "transparent"
			border.color: Qt.rgba(1, 1, 1, 0.08)
			border.width: 1
		}

		Behavior on opacity {
			NumberAnimation { duration: 300 }
		}

		// Fast position updates for smooth progress
		Timer {
			id: positionTimer
			interval: 100
			running: mediaPlayer.isActive
			repeat: true
			onTriggered: positionProc.running = true
		}

		// Slower metadata updates
		Timer {
			interval: 1000
			running: true
			repeat: true
			onTriggered: {
				statusProc.running = true
				metadataProc.running = true
			}
		}

		Process {
			id: statusProc
			command: ["playerctl", "status"]
			running: false
			stdout: SplitParser {
				onRead: line => mediaPlayer.playerStatus = line.trim()
			}
			onExited: if (exitCode !== 0) mediaPlayer.playerStatus = ""
		}

		Process {
			id: metadataProc
			command: ["playerctl", "metadata", "--format", "{{title}}\t{{artist}}\t{{playerName}}\t{{mpris:artUrl}}\t{{mpris:length}}"]
			running: false
			stdout: SplitParser {
				onRead: function(line) {
					var parts = line.split("\t")
					if (parts.length >= 5) {
						mediaPlayer.trackTitle = parts[0] || ""
						mediaPlayer.trackArtist = parts[1] || ""
						mediaPlayer.playerName = parts[2] || ""
						mediaPlayer.artUrl = parts[3] || ""
						mediaPlayer.trackLength = parseFloat(parts[4]) / 1000000 || 0
					}
				}
			}
			onExited: if (exitCode !== 0) {
				mediaPlayer.trackTitle = ""
				mediaPlayer.trackArtist = ""
			}
		}

		Process {
			id: positionProc
			command: ["playerctl", "position"]
			running: false
			stdout: SplitParser {
				onRead: line => mediaPlayer.currentPosition = parseFloat(line) || 0
			}
		}

		// Control processes
		Process {
			id: prevProc
			command: ["playerctl", "previous"]
		}

		Process {
			id: playPauseProc
			command: ["playerctl", "play-pause"]
		}

		Process {
			id: nextProc
			command: ["playerctl", "next"]
		}

		Process {
			id: seekProc
			property real targetPosition: 0
			command: ["playerctl", "position", targetPosition.toFixed(1)]
		}

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 15
			spacing: 12

			// Top row: Album art + info + controls
			RowLayout {
				spacing: 15

				// Album Art - Material Design
				Rectangle {
					Layout.preferredWidth: 64
					Layout.preferredHeight: 64
					radius: 12
					color: Qt.rgba(0.18, 0.18, 0.19, 1.0)
					clip: true

					Image {
						anchors.fill: parent
						source: mediaPlayer.artUrl
						fillMode: Image.PreserveAspectCrop
						visible: source.toString().length > 0
					}

					Label {
						anchors.centerIn: parent
						font.family: "JetBrainsMono Nerd Font"
						font.pointSize: 24
						color: "#938F99"
						text: "󰎇"
						visible: !parent.children[0].visible
					}
				}

				// Track Info - Material Design
				ColumnLayout {
					Layout.fillWidth: true
					spacing: 4

					Label {
						font.family: "Roboto"
						font.pointSize: 14
						font.weight: Font.Medium
						color: "#E6E1E5"
						text: mediaPlayer.trackTitle || "No Title"
						elide: Text.ElideRight
						Layout.fillWidth: true
					}

					Label {
						font.family: "Roboto"
						font.pointSize: 12
						color: "#A1A1A1"
						text: mediaPlayer.trackArtist || "Unknown Artist"
						elide: Text.ElideRight
						Layout.fillWidth: true
					}
				}

				// Controls
				RowLayout {
					spacing: 12
					Layout.alignment: Qt.AlignVCenter

					Label {
						font.family: "JetBrainsMono Nerd Font"
						font.pointSize: 16
						color: mouseAreaPrev.containsMouse ? "#D0BCFF" : "#938F99"
						text: "󰼨"
						MouseArea {
							id: mouseAreaPrev
							anchors.fill: parent
							hoverEnabled: true
							onClicked: prevProc.running = true
						}
					}

					Label {
						font.family: "JetBrainsMono Nerd Font"
						font.pointSize: 20
						color: mouseAreaPlay.containsMouse ? "#D0BCFF" : "#D0BCFF"
						text: mediaPlayer.playerStatus === "Playing" ? "󰏤" : "󰐊"
						MouseArea {
							id: mouseAreaPlay
							anchors.fill: parent
							hoverEnabled: true
							onClicked: playPauseProc.running = true
						}
					}

					Label {
						font.family: "JetBrainsMono Nerd Font"
						font.pointSize: 16
						color: mouseAreaNext.containsMouse ? "#D0BCFF" : "#938F99"
						text: "󰼧"
						MouseArea {
							id: mouseAreaNext
							anchors.fill: parent
							hoverEnabled: true
							onClicked: nextProc.running = true
						}
					}
				}
			}

			// Material Progress Bar with drag-to-seek
			Rectangle {
				id: progressContainer
				Layout.fillWidth: true
				Layout.preferredHeight: 24
				color: "transparent"

				ColumnLayout {
					anchors.fill: parent
					spacing: 4

					// Time labels row
					RowLayout {
						Layout.fillWidth: true
						spacing: 0

						Label {
							font.family: "Roboto"
							font.pointSize: 10
							color: "#E6E1E5"
							opacity: 0.7
							text: {
								var secs = Math.floor(mediaPlayer.currentPosition)
								var m = Math.floor(secs / 60)
								var s = secs % 60
								return m + ":" + (s < 10 ? "0" : "") + s
							}
						}

						Item { Layout.fillWidth: true }

						Label {
							font.family: "Roboto"
							font.pointSize: 10
							color: "#E6E1E5"
							opacity: 0.7
							text: {
								var secs = Math.floor(mediaPlayer.trackLength)
								var m = Math.floor(secs / 60)
								var s = secs % 60
								return m + ":" + (s < 10 ? "0" : "") + s
							}
						}
					}

					// Progress bar track
					Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 6
						radius: 3
						color: Qt.rgba(0.25, 0.24, 0.26, 1.0)

						// Progress fill
						Rectangle {
							id: progressFill
							anchors.left: parent.left
							anchors.top: parent.top
							anchors.bottom: parent.bottom
							width: mediaPlayer.trackLength > 0 ? (mediaPlayer.currentPosition / mediaPlayer.trackLength) * parent.width : 0
							radius: 3
							color: "#D0BCFF"

							Behavior on width {
								NumberAnimation { duration: 50; easing.type: Easing.Linear }
							}
						}

						// Draggable handle
						Rectangle {
							id: progressHandle
							anchors.verticalCenter: parent.verticalCenter
							x: progressFill.width - width / 2
							width: 14
							height: 14
							radius: 7
							color: "#D0BCFF"
							visible: mediaPlayer.isActive

							Behavior on x {
								NumberAnimation { duration: 50; easing.type: Easing.Linear }
							}
						}

						// Seek interaction
						MouseArea {
							anchors.fill: parent
							hoverEnabled: true

							function seekAt(mouseX) {
								if (mediaPlayer.trackLength <= 0) return
								var pct = Math.max(0, Math.min(1, mouseX / width))
								var targetPos = pct * mediaPlayer.trackLength
								seekProc.targetPosition = targetPos
								seekProc.running = true
								// Update immediately for responsiveness
								mediaPlayer.currentPosition = targetPos
							}

							onClicked: seekAt(mouse.x)
							onPositionChanged: if (pressed) seekAt(mouse.x)
						}
					}
				}
			}
		}
	}

	ColumnLayout {
		// Uncommenting this will make the password entry invisible except on the active monitor.
		// visible: Window.active

		anchors {
			horizontalCenter: parent.horizontalCenter
			top: mediaPlayer.bottom
			topMargin: 40
		}

		RowLayout {
			spacing: 10

			TextField {
				id: passwordBox

				implicitWidth: 400
				padding: 15

				focus: true
				enabled: !root.context.unlockInProgress
				echoMode: TextInput.Password
				inputMethodHints: Qt.ImhSensitiveData

				// Glassmorphism styling
				background: Rectangle {
					color: Qt.rgba(0.2, 0.2, 0.3, 0.5)
					border.color: Qt.rgba(0.5, 0.5, 0.7, 0.3)
					border.width: 1
					radius: 8
				}
				
				color: "#ffffff"
				font.family: "sans-serif"
				selectByMouse: true

				// Update the text in the context when the text in the box changes.
				onTextChanged: root.context.currentText = this.text;

				// Try to unlock when enter is pressed.
				onAccepted: root.context.tryUnlock();

				// Update the text in the box to match the text in the context.
				// This makes sure multiple monitors have the same text.
				Connections {
					target: root.context

					function onCurrentTextChanged() {
						passwordBox.text = root.context.currentText;
					}
				}
			}

			Button {
				text: "Unlock"
				padding: 15

				// don't steal focus from the text box
				focusPolicy: Qt.NoFocus

				enabled: !root.context.unlockInProgress && root.context.currentText !== "";
				onClicked: root.context.tryUnlock();

				// Glassmorphism styling
				background: Rectangle {
					color: enabled ? Qt.rgba(0.3, 0.3, 0.5, 0.6) : Qt.rgba(0.2, 0.2, 0.3, 0.3)
					border.color: Qt.rgba(0.6, 0.6, 0.8, 0.4)
					border.width: 1
					radius: 8
				}
				
				contentItem: Text {
					text: parent.text
					color: enabled ? "#ffffff" : "#aaaaaa"
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					font.family: "sans-serif"
				}
			}
		}

		Label {
			visible: root.context.showFailure
			text: "Incorrect password"
			color: "#ff6b6b"
			font.family: "sans-serif"
			font.pointSize: 12
		}
	}
}
