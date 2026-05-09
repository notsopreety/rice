import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Layouts
import "theme"
import "osd"

ShellRoot {
    id: shellRoot

    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData
            
            readonly property bool isVertical: settings.position === "left" || settings.position === "right"
            
            WlrLayershell.layer: WlrLayershell.Top
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.exclusiveZone: isVertical ? barWindow.implicitWidth : barWindow.implicitHeight
            
            FileView {
                id: settingsFile
                path: Quickshell.env("HOME") + "/.config/quickshell/bar/settings.json"
                JsonAdapter {
                    id: settings
                    property int height: 40
                    property real bgOpacity: 0.8
                    property bool usePywal: true
                    property string position: "top"
                    property int radius: 12
                    property var margins: ({ "top": 4, "bottom": 4, "left": 10, "right": 10 })
                    property var groups: ({ "left": [], "center": [], "right": [] })
                }
            }

            anchors {
                top: settings.position !== "bottom"
                bottom: settings.position !== "top"
                left: settings.position !== "right"
                right: settings.position !== "left"
            }

            margins {
                top: (settings.position === "top" || isVertical) ? settings.margins.top : 0
                bottom: (settings.position === "bottom" || isVertical) ? settings.margins.bottom : 0
                left: (settings.position === "left" || !isVertical) ? settings.margins.left : 0
                right: (settings.position === "right" || !isVertical) ? settings.margins.right : 0
            }

            implicitWidth: isVertical ? settings.height : -1
            implicitHeight: isVertical ? -1 : settings.height
            color: "transparent"

            function getWalColor(key, fallback) { return Colors.getWal(key, fallback); }
            property color backgroundColor: Colors.grey900
            property color accentColor: Colors.purple200

            Rectangle {
                id: barBg
                anchors.fill: parent
                color: backgroundColor
                opacity: settings.bgOpacity
                radius: settings.radius
                border.width: 1
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
            }

            GridLayout {
                id: barLayout
                anchors.fill: parent
                anchors.margins: 4
                columns: isVertical ? 1 : 3
                rows: isVertical ? 3 : 1
                columnSpacing: 0
                rowSpacing: 0

                Item {
                    Layout.fillWidth: !isVertical; Layout.fillHeight: isVertical
                    Layout.alignment: isVertical ? Qt.AlignTop : Qt.AlignLeft
                    Row { visible: !isVertical; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Repeater { model: settings.groups.left; delegate: Loader { source: "modules/" + (modelData.charAt(0).toUpperCase() + modelData.slice(1)) + ".qml" } }
                    }
                    Column { visible: isVertical; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                        Repeater { model: settings.groups.left; delegate: Loader { source: "modules/" + (modelData.charAt(0).toUpperCase() + modelData.slice(1)) + ".qml" } }
                    }
                }

                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.alignment: Qt.AlignCenter
                    Row { visible: !isVertical; anchors.centerIn: parent; spacing: 8
                        Repeater { model: settings.groups.center; delegate: Loader { source: "modules/" + (modelData.charAt(0).toUpperCase() + modelData.slice(1)) + ".qml" } }
                    }
                    Column { visible: isVertical; anchors.centerIn: parent; spacing: 8
                        Repeater { model: settings.groups.center; delegate: Loader { source: "modules/" + (modelData.charAt(0).toUpperCase() + modelData.slice(1)) + ".qml" } }
                    }
                }

                Item {
                    id: rightContainer
                    Layout.fillWidth: !isVertical; Layout.fillHeight: isVertical
                    Layout.alignment: isVertical ? Qt.AlignBottom : Qt.AlignRight
                    Row { id: rightRow
                        visible: !isVertical; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; spacing: 8
                        Repeater { model: settings.groups.right; delegate: Loader { source: "modules/" + (modelData.charAt(0).toUpperCase() + modelData.slice(1)) + ".qml" } }
                    }
                    Column { id: rightColumn
                        visible: isVertical; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; spacing: 8
                        Repeater { model: settings.groups.right; delegate: Loader { source: "modules/" + (modelData.charAt(0).toUpperCase() + modelData.slice(1)) + ".qml" } }
                    }
                }
            }

            // ── Responsive Popup Positioning ───────────────────
            
            function getPopupX(popupWidth) {
                if (isVertical) {
                    if (settings.position === "left") return barWindow.width + 10
                    if (settings.position === "right") return -popupWidth - 10
                }
                var x = SessionState.anchorX + (SessionState.anchorWidth / 2) - (popupWidth / 2)
                return Math.max(10, Math.min(x, barWindow.width - popupWidth - 10))
            }

            function getPopupY(popupHeight) {
                if (!isVertical) {
                    if (settings.position === "top") return barWindow.height + 10
                    if (settings.position === "bottom") return -popupHeight - 10
                }
                var y = SessionState.anchorY + (SessionState.anchorHeight / 2) - (popupHeight / 2)
                return Math.max(10, Math.min(y, barWindow.height - popupHeight - 10))
            }
            
            WifiPopup {
                id: wifiPopup
                screenObj: modelData
                xPos: {
                    var pos = barBg.mapToGlobal(getPopupX(width), 0)
                    return pos.x
                }
                yPos: {
                    var pos = barBg.mapToGlobal(0, getPopupY(height))
                    return pos.y
                }
            }
            
            AudioPopup {
                anchor.window: barWindow
                anchor.rect.x: getPopupX(implicitWidth)
                anchor.rect.y: getPopupY(implicitHeight)
            }
            
            BluetoothPopup {
                anchor.window: barWindow
                anchor.rect.x: getPopupX(implicitWidth)
                anchor.rect.y: getPopupY(implicitHeight)
            }

            PowerProfilePopup {
                anchor.window: barWindow
                anchor.rect.x: getPopupX(implicitWidth)
                anchor.rect.y: getPopupY(implicitHeight)
            }

            TooltipPopup {
                screen: modelData
            }
        }
    }
}
