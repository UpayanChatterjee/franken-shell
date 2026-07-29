import QtQuick

QtObject {
    property int summaryCount: 0

    function summaryObject(): var {
        summaryCount += 1;
        return Object.freeze({
            "project": "Franken Shell",
            "shellReady": true,
            "privateWindowTitle": undefined
        });
    }
}
