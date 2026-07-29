import QtQuick

QtObject {
    property int reloadCount: 0

    function requestReload(): string {
        reloadCount += 1;
        return "configuration reload requested";
    }
}
