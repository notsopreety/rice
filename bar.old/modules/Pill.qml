import QtQuick
import Quickshell
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    
    property alias mouseArea: mouseArea
    property alias content: layout.data
    property color pillColor: Qt.rgba(barWindow.backgroundColor.r, barWindow.backgroundColor.g, barWindow.backgroundColor.b, 0.45)
    property int padding: 12
    
    // In vertical mode, the width and height are swapped for the layout
    implicitWidth: barWindow.isVertical ? (layout.implicitHeight + (padding * 2)) : (layout.implicitWidth + (padding * 2))
    implicitHeight: barWindow.isVertical ? (layout.implicitWidth + (padding * 2)) : (barWindow.implicitHeight - 6)
    
    radius: 12
    color: pillColor
    
    border.width: 1
    border.color: mouseArea.containsMouse 
        ? Qt.rgba(barWindow.accentColor.r, barWindow.accentColor.g, barWindow.accentColor.b, 0.4)
        : Qt.rgba(barWindow.accentColor.r, barWindow.accentColor.g, barWindow.accentColor.b, 0.15)
    
    scale: mouseArea.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    Behavior on border.color { ColorAnimation { duration: 200 } }
    
    Item {
        id: layoutContainer
        anchors.centerIn: parent
        width: barWindow.isVertical ? layout.implicitHeight : layout.implicitWidth
        height: barWindow.isVertical ? layout.implicitWidth : layout.implicitHeight
        
        Row {
            id: layout
            spacing: 8
            anchors.centerIn: parent
            
            // Rotation logic
            rotation: barWindow.isVertical ? 90 : 0
            
            // Fix transformation origin for clean rotation
            transformOrigin: Item.Center
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        
        onClicked: (mouse) => {
            var pos = root.mapToItem(barWindow.contentItem, 0, 0)
            SessionState.anchorX = pos.x
            SessionState.anchorY = pos.y
            SessionState.anchorWidth = root.width
            SessionState.anchorHeight = root.height
            if (mouse.button === Qt.RightButton) {
                root.rightClicked()
            } else {
                root.clicked()
            }
        }
    }
    
    signal clicked()
    signal rightClicked()
}
