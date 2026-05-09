pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        JsonAdapter {
            id: wal
            property var colors: ({})
            property var special: ({})
        }
    }

    function getWal(key, fallback) {
        if (key.startsWith("special.")) {
            var s = key.split(".")[1];
            return (wal.special && wal.special[s]) ? wal.special[s] : fallback;
        }
        return (wal.colors && wal.colors[key]) ? wal.colors[key] : fallback;
    }

    // Material-like palette mapped to Pywal
    readonly property color white:    getWal("special.foreground", "#ffffff")
    readonly property color black:    getWal("special.background", "#000000")
    
    // Grey scale
    readonly property color grey50:   getWal("special.foreground", "#fafafa")
    readonly property color grey100:  Qt.darker(grey50, 1.1)
    readonly property color grey200:  Qt.darker(grey50, 1.2)
    readonly property color grey300:  Qt.darker(grey50, 1.3)
    readonly property color grey400:  Qt.darker(grey50, 1.4)
    readonly property color grey500:  Qt.darker(grey50, 1.5)
    readonly property color grey600:  Qt.lighter(grey900, 1.6)
    readonly property color grey700:  Qt.lighter(grey900, 1.4)
    readonly property color grey800:  Qt.lighter(grey900, 1.2)
    readonly property color grey900:  getWal("special.background", "#212121")
    
    // Theme colors mapped to Pywal indices
    readonly property color purple200: getWal("color1", "#CE93D8")
    readonly property color purple500: getWal("color1", "#9C27B0")
    readonly property color deepPurple200: getWal("color5", "#B39DDB")
    readonly property color deepPurple500: getWal("color5", "#673AB7")
    readonly property color red200:    getWal("color1", "#ef9a9a")
    readonly property color red400:    getWal("color1", "#ef5350")
    readonly property color lightBlue200: getWal("color4", "#81D4FA")
    readonly property color teal200:   getWal("color6", "#80cbc4")
    readonly property color teal400:   getWal("color6", "#26a69a")
    readonly property color orange200: getWal("color3", "#ffcc80")
    readonly property color yellow200: getWal("color3", "#fff59d")
    readonly property color yellow600: getWal("color3", "#fdd835")
    readonly property color green200:  getWal("color2", "#a5d6a7")
    
    // Additional colors used in popups
    readonly property color blueGrey700: getWal("color8", "#455A64")
    readonly property color blueGrey800: getWal("color0", "#37474F")
    readonly property color blueGrey900: getWal("special.background", "#263238")
}
