import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    visible: SessionState.tooltipVisible && SessionState.tooltipText !== ""
    
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-tooltip"
    
    // Logic for responsive positioning based on bar orientation
    readonly property bool isVertical: barWindow.isVertical
    readonly property string position: settings.position
    
    anchors.top: true
    anchors.left: true
    
    // Position calculation
    margins.left: {
        if (isVertical) {
            if (position === "left") return SessionState.tooltipX + SessionState.anchorWidth + 8
            if (position === "right") return SessionState.tooltipX - innerRect.width - 8
        }
        // Horizontal (top/bottom)
        return SessionState.tooltipX + (SessionState.anchorWidth / 2) - (innerRect.width / 2)
    }
    
    margins.top: {
        if (!isVertical) {
            if (position === "top") return SessionState.tooltipY + SessionState.anchorHeight + 8
            if (position === "bottom") return SessionState.tooltipY - innerRect.height - 8
        }
        // Vertical (left/right)
        return SessionState.tooltipY + (SessionState.anchorHeight / 2) - (innerRect.height / 2)
    }
    
    implicitWidth: innerRect.width
    implicitHeight: innerRect.height
    color: "transparent"
    focusable: false
    mask: Region {}
    
    Rectangle {
        id: innerRect
        width: tooltipText.implicitWidth + 24
        height: tooltipText.implicitHeight + 12
        radius: 6
        color: Colors.grey900
        border.color: Colors.grey700
        border.width: 1
        
        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: SessionState.tooltipText
            color: Colors.white
            font.pixelSize: 11
            font.bold: true
            font.family: "Inter, Roboto, sans-serif"
        }
    }
}
