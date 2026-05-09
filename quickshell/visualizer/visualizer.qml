import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: root
    
    WlrLayershell.layer: WlrLayershell.Background
    WlrLayershell.namespace: "cava-visualizer"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/visualizer/settings.json"
        JsonAdapter {
            id: settings
            property int winX: 0
            property int winY: 0
            property int winZ: 600
            property int thickness: 80
            property bool fullLength: true
            property string position: "bottom"
            
            property string vizMode: "bars"
            property int barCount: 32
            property bool autoBar: true
            property int barSpacing: 4
            property int barWidth: 0
            
            property int curvePoints: 32
            property int curveLineWidth: 2
            
            property string orientation: "bottom"
            property int sensitivity: 100
            property string channels: "stereo"
            
            property string colorChoice: "accent"
            property real bgOpacity: 0.4
            property string bgColor: "#0a0a0a"
            property real opacity: 1.0
            property bool usePywal: true
            property int silenceTimeout: 5
        }
    }

    // ── Positioning Logic ──
    anchors {
        top: settings.position === "top"
        bottom: settings.position === "bottom"
        left: settings.fullLength || settings.position === "left"
        right: settings.fullLength || settings.position === "right"
    }

    // Centering and offset logic
    margins {
        top: settings.position === "top" ? settings.winY : 0
        bottom: settings.position === "bottom" ? settings.winY : 0
        left: (settings.fullLength || settings.position === "left") ? 0 : settings.winX
        right: (settings.fullLength || settings.position === "right") ? 0 : 0
    }

    implicitWidth: settings.fullLength ? -1 : settings.winZ
    implicitHeight: settings.thickness
    color: "transparent"

    // ── Pywal Integration ──
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

    property color accentColor: getWalColor("color1", "#ff2d55")
    property color primaryColor: getWalColor("special.foreground", "white")
    property color secondaryColor: getWalColor("color2", "#ff2d55")
    property color backgroundColor: (settings.bgColor === "none" || settings.bgColor === "transparent") ? "transparent" : getWalColor("special.background", settings.bgColor)

    // ── CAVA Logic ──
    property var barValues: []
    property bool isSilent: true
    property bool fadedOut: true
    property bool hasPlayedOnce: false

    readonly property int effectiveBarCount: {
        if (!settings.autoBar) return (settings.vizMode === "bars" ? settings.barCount : settings.curvePoints);
        if (settings.vizMode !== "bars") return settings.curvePoints;
        let targetW = settings.barWidth > 0 ? settings.barWidth : 8;
        let w = settings.fullLength ? root.width : settings.winZ;
        let count = Math.floor(w / (targetW + settings.barSpacing));
        return Math.max(4, count);
    }

    onIsSilentChanged: {
        if (isSilent) {
            if (hasPlayedOnce) silenceTimer.restart()
        } else {
            hasPlayedOnce = true
            silenceTimer.stop()
            fadedOut = false
        }
    }

    Timer {
        id: silenceTimer
        repeat: false
        interval: settings.silenceTimeout * 1000
        onTriggered: fadedOut = true
    }

    function rebuildConfig() { rebuildTimer.restart() }

    Timer {
        id: rebuildTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (cavaProcess.running) {
                cavaProcess.running = false
            } else if (!configWriter.running) {
                configWriter.running = true
            }
        }
    }

    Process {
        id: configWriter
        command: [
            "bash", "-c",
            "mkdir -p /tmp/quickshell-cava && cat > /tmp/quickshell-cava/config << 'CAVAEOF'\n" +
            "[general]\n" +
            "bars = "        + root.effectiveBarCount + "\n" +
            "framerate = 60\n" +
            "sensitivity = " + settings.sensitivity   + "\n" +
            "channels = "    + settings.channels      + "\n" +
            "\n" +
            "[output]\n" +
            "method = raw\n" +
            "channels = "    + settings.channels      + "\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 1000\n" +
            "bar_delimiter = 59\n" +
            "frame_delimiter = 10\n" +
            "CAVAEOF"
        ]
        running: false
        onRunningChanged: if (!running) cavaProcess.running = true
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", "/tmp/quickshell-cava/config"]
        running: false
        onRunningChanged: if (!running && !configWriter.running) configWriter.running = true
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (!line) return;
                const parts = line.split(";");
                const vals = [];
                let silent = true;
                for (let i = 0; i < parts.length; i++) {
                    const n = parseInt(parts[i], 10);
                    if (!isNaN(n)) {
                        const v = Math.min(1.0, n / 1000.0);
                        vals.push(v);
                        if (v > 0.02) silent = false;
                    }
                }
                if (vals.length > 0) {
                    root.barValues = vals;
                    root.isSilent = silent;
                }
            }
        }
    }

    Component.onCompleted: rebuildConfig()
    onEffectiveBarCountChanged: rebuildConfig()
    onWidthChanged: if (settings.autoBar) rebuildConfig()

    // ── UI ──
    Item {
        id: mainContainer
        anchors.fill: parent
        opacity: fadedOut ? 0.0 : settings.opacity
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

        Rectangle {
            id: bg
            anchors.fill: parent
            visible: settings.bgColor !== "none" && settings.bgColor !== "transparent"
            color: backgroundColor
            opacity: settings.bgOpacity
            radius: 12
        }

        Item {
            id: vis
            anchors.fill: parent
            clip: true

            readonly property real effectiveBarW: settings.barWidth > 0
                ? settings.barWidth
                : Math.max(1, (width - (root.effectiveBarCount - 1) * settings.barSpacing) / root.effectiveBarCount)

            readonly property real effectiveBarH: settings.barWidth > 0
                ? settings.barWidth
                : Math.max(1, (height - (root.effectiveBarCount - 1) * settings.barSpacing) / root.effectiveBarCount)

            readonly property color foregroundColor: {
                if (settings.colorChoice === "accent") return accentColor;
                if (settings.colorChoice === "secondary") return secondaryColor;
                return primaryColor;
            }

            // Horizontal Bars
            Row {
                visible: settings.vizMode === "bars" && (settings.orientation === "bottom" || settings.orientation === "top" || settings.orientation === "horizontal")
                anchors.fill: parent
                spacing: settings.barSpacing

                Repeater {
                    model: settings.vizMode === "bars" ? root.effectiveBarCount : 0
                    delegate: Rectangle {
                        required property int index
                        readonly property real norm: root.barValues[index] ?? 0.0
                        width: vis.effectiveBarW
                        height: Math.max(1, norm * vis.height)
                        y: settings.orientation === "bottom" ? vis.height - height : (settings.orientation === "horizontal" ? (vis.height - height) / 2 : 0)
                        radius: width / 2
                        color: Qt.rgba(vis.foregroundColor.r, vis.foregroundColor.g, vis.foregroundColor.b, 0.7 + norm * 0.3)
                        Behavior on height { SmoothedAnimation { velocity: vis.height * 4 } }
                    }
                }
            }

            // Vertical Bars
            Column {
                visible: settings.vizMode === "bars" && (settings.orientation === "left" || settings.orientation === "right" || settings.orientation === "vertical")
                anchors.fill: parent
                spacing: settings.barSpacing

                Repeater {
                    model: settings.vizMode === "bars" ? root.effectiveBarCount : 0
                    delegate: Rectangle {
                        required property int index
                        readonly property real norm: root.barValues[index] ?? 0.0
                        height: vis.effectiveBarH
                        width: Math.max(1, norm * vis.width)
                        x: settings.orientation === "right" ? vis.width - width : (settings.orientation === "vertical" ? (vis.width - width) / 2 : 0)
                        radius: height / 2
                        color: Qt.rgba(vis.foregroundColor.r, vis.foregroundColor.g, vis.foregroundColor.b, 0.7 + norm * 0.3)
                        Behavior on width { SmoothedAnimation { velocity: vis.width * 4 } }
                    }
                }
            }

            // Curve Mode
            Canvas {
                id: curveCanvas
                visible: settings.vizMode === "curve-outline" || settings.vizMode === "curve-filled"
                anchors.fill: parent
                Connections {
                    target: root
                    function onBarValuesChanged() { if (curveCanvas.visible) curveCanvas.requestPaint() }
                }
                onPaint: {
                    const ctx = getContext("2d"), w = width, h = height, vals = root.barValues, n = vals.length
                    if (n < 2) return;
                    ctx.clearRect(0, 0, w, h)
                    const orient = settings.orientation, points = []
                    for (let i = 0; i < n; i++) {
                        const t = i / (n - 1), amp = vals[i]
                        let px, py
                        if (orient === "top") { px = t * w; py = amp * h }
                        else if (orient === "horizontal") { px = t * w; py = h / 2 - amp * (h / 2) }
                        else if (orient === "vertical") { px = w / 2 - amp * (w / 2); py = t * h }
                        else if (orient === "left") { px = amp * w; py = t * h }
                        else if (orient === "right") { px = w - amp * w; py = t * h }
                        else { px = t * w; py = h - amp * h }
                        points.push({ x: px, y: py })
                    }
                    function drawSpline(pts) {
                        const len = pts.length
                        ctx.beginPath(); ctx.moveTo(pts[0].x, pts[0].y)
                        for (let i = 0; i < len - 1; i++) {
                            const p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(len - 1, i + 2)]
                            const cp1x = p1.x + (p2.x - p0.x) / 6, cp1y = p1.y + (p2.y - p0.y) / 6
                            const cp2x = p2.x - (p3.x - p1.x) / 6, cp2y = p2.y - (p3.y - p1.y) / 6
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
                        }
                    }
                    const color = vis.foregroundColor, r = color.r, g = color.g, b = color.b, a = settings.opacity
                    const isFilled = settings.vizMode === "curve-filled"
                    if (orient === "horizontal") {
                        drawSpline(points); const mirrorH = points.map(p => ({ x: p.x, y: h - p.y }))
                        for (let i = mirrorH.length - 2; i >= 0; i--) {
                            const p0 = mirrorH[Math.min(mirrorH.length - 1, i + 2)], p1 = mirrorH[i + 1], p2 = mirrorH[i], p3 = mirrorH[Math.max(0, i - 1)]
                            const cp1x = p1.x + (p2.x - p0.x) / 6, cp1y = p1.y + (p2.y - p0.y) / 6, cp2x = p2.x - (p3.x - p1.x) / 6, cp2y = p2.y - (p3.y - p1.y) / 6
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
                        }
                        ctx.closePath()
                        if (isFilled) { ctx.fillStyle = Qt.rgba(r, g, b, a); ctx.fill() }
                        else { ctx.strokeStyle = Qt.rgba(r, g, b, a); ctx.lineWidth = settings.curveLineWidth; ctx.stroke() }
                    } else if (orient === "vertical") {
                        drawSpline(points); const mirrorV = points.map(p => ({ x: w - p.x, y: p.y }))
                        for (let i = mirrorV.length - 2; i >= 0; i--) {
                            const p0 = mirrorV[Math.min(mirrorV.length - 1, i + 2)], p1 = mirrorV[i + 1], p2 = mirrorV[i], p3 = mirrorV[Math.max(0, i - 1)]
                            const cp1x = p1.x + (p2.x - p0.x) / 6, cp1y = p1.y + (p2.y - p0.y) / 6, cp2x = p2.x - (p3.x - p1.x) / 6, cp2y = p2.y - (p3.y - p1.y) / 6
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
                        }
                        ctx.closePath()
                        if (isFilled) { ctx.fillStyle = Qt.rgba(r, g, b, a); ctx.fill() }
                        else { ctx.strokeStyle = Qt.rgba(r, g, b, a); ctx.lineWidth = settings.curveLineWidth; ctx.stroke() }
                    } else {
                        drawSpline(points)
                        if (isFilled) {
                            if (orient === "left") { ctx.lineTo(0, points[n-1].y); ctx.lineTo(0, points[0].y) }
                            else if (orient === "right") { ctx.lineTo(w, points[n-1].y); ctx.lineTo(w, points[0].y) }
                            else { const baselineY = orient === "top" ? 0 : h; ctx.lineTo(points[n-1].x, baselineY); ctx.lineTo(points[0].x, baselineY) }
                            ctx.closePath(); ctx.fillStyle = Qt.rgba(r, g, b, a); ctx.fill()
                        } else { ctx.strokeStyle = Qt.rgba(r, g, b, a); ctx.lineWidth = settings.curveLineWidth; ctx.stroke() }
                    }
                }
            }
        }
    }
}
