pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Layouts

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
                    property int height: 35
                    property real bgOpacity: 0.7
                    property bool usePywal: true
                    property string position: "top"
                    property int radius: 16
                    property var margins: ({ "top": 8, "bottom": 0, "left": 12, "right": 12 })
                    property var groups: ({ "left": [], "center": [], "right": [] })
                }
            }

            FileView {
                id: walColorsFile
                path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
                JsonAdapter {
                    id: walColors
                    property var colors: ({})
                    property var special: ({})
                }
            }

            function getWalColor(key, fallback) {
                if (!settings.usePywal) return fallback;
                if (key.startsWith("special.")) {
                    var s = key.split(".")[1];
                    return (walColors.special && walColors.special[s]) ? walColors.special[s] : fallback;
                }
                return (walColors.colors && walColors.colors[key]) ? walColors.colors[key] : fallback;
            }

            property color bgColor: getWalColor("color0", "#1e1e2e")
            property color surfaceColor: getWalColor("color1", "#313244")
            property color accentColor: getWalColor("color2", "#cba6f7")
            property color textColor: getWalColor("special.foreground", "#cdd6f4")
            property color mutedColor: getWalColor("color7", "#9399b2")

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

            Rectangle {
                id: barBg
                anchors.fill: parent
                color: bgColor
                opacity: settings.bgOpacity
                radius: settings.radius

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: accentColor
                    opacity: 0.3
                    radius: [settings.radius, settings.radius, 0, 0]
                }
            }

            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
            }

            Row {
                id: centerRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
            }

            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
            }

            // Manual module loading using Connections and Timer
            Component.onCompleted: {
                timer.start()
            }

            Timer {
                id: timer
                interval: 100
                onTriggered: loadAllModules()
            }

            function capitalizeFirst(str) {
                return str.charAt(0).toUpperCase() + str.slice(1)
            }

            function loadAllModules() {
                loadModulesForSection(settings.groups.left, leftRow)
                loadModulesForSection(settings.groups.center, centerRow)
                loadModulesForSection(settings.groups.right, rightRow)
            }

            function loadModulesForSection(moduleList, container) {
                if (!moduleList || moduleList.length === 0) return
                for (var i = 0; i < moduleList.length; i++) {
                    var moduleName = capitalizeFirst(moduleList[i])
                    var comp = Qt.createComponent("modules/" + moduleName + ".qml")
                    if (comp.status === Component.Ready) {
                        var item = comp.createObject(container)
                    } else {
                        console.log("Failed to load module:", moduleName, comp.errorString())
                    }
                }
            }

            function getPopupX(popupWidth) {
                var x = barWindow.width / 2 - popupWidth / 2
                return Math.max(10, Math.min(x, barWindow.width - popupWidth - 10))
            }

            function getPopupY(popupHeight) {
                if (settings.position === "top") return barWindow.height + 8
                return -popupHeight - 8
            }
        }
    }
}