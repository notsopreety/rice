import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: shellRoot

    property bool floatingMode: true

    UserConfig {
        id: userConfig
    }

    function forEachWindow(callback) {
        if (panelWindow)
            callback(panelWindow);
    }

    function anyOverviewOpen() {
        return panelWindow && panelWindow.overviewPhase !== "closed";
    }

    function prepareOverviewAll() {
        shellRoot.forEachWindow((window) => window.prepareOverview());
    }

    function cancelPreparedOverviewAll() {
        shellRoot.forEachWindow((window) => window.cancelPreparedOverview());
    }

    function openOverviewAll() {
        shellRoot.forEachWindow((window) => window.openOverview());
    }

    function closeOverviewAll() {
        shellRoot.forEachWindow((window) => window.closeOverview());
    }

    function toggleOverviewAll() {
        if (shellRoot.anyOverviewOpen())
            shellRoot.closeOverviewAll();
        else
            shellRoot.openOverviewAll();
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            shellRoot.toggleOverviewAll();
        }

        function open() {
            shellRoot.openOverviewAll();
        }

        function close() {
            shellRoot.closeOverviewAll();
        }

        function refreshWallpaperCache() {
            shellRoot.forEachWindow((window) => {
                if (window && window.prewarmWallpaperCache)
                    window.prewarmWallpaperCache();
            });
        }
    }

    IpcHandler {
        target: "floating"

        function toggle() {
            shellRoot.floatingMode = !shellRoot.floatingMode;
        }

        function enable() {
            shellRoot.floatingMode = true;
        }

        function disable() {
            shellRoot.floatingMode = false;
        }
    }

    GlobalShortcut {
        appid: userConfig.overviewGlobalShortcutAppid
        name: userConfig.overviewGlobalShortcutName

        onPressed: shellRoot.toggleOverviewAll()
    }

    DynamicIslandWindow {
        id: panelWindow
        screen: Quickshell.screens[0]
        shellRootController: shellRoot
    }
}
