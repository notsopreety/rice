pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool visible: false
    property bool powerPopupVisible: false
    property bool bluetoothPopupVisible: false
    property bool wifiPopupVisible: false
    
    // Anchoring for OSDs
    property int anchorX: 0
    property int anchorY: 0
    property int anchorWidth: 0
    property int anchorHeight: 0

    // Tooltip State
    property string tooltipText: ""
    property bool tooltipVisible: false
    property int tooltipX: 0
    property int tooltipY: 0

    function showTooltip(text, x, y, w, h) {
        tooltipText = text
        tooltipX = x + (w / 2)
        tooltipY = y
        tooltipVisible = true
    }

    function hideTooltip() {
        tooltipVisible = false
    }

    function show() { visible = true }
    function hide() { visible = false }

    function closeAllPopups() {
        powerPopupVisible = false
        bluetoothPopupVisible = false
        wifiPopupVisible = false
        visible = false
        AudioState.hide()
    }
}
