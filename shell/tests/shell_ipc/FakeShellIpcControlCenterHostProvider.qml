import QtQuick

QtObject {
    property int openHostCount: 0
    property int revision: 12
    property int toggleCount: 0

    function requestKeyboardToggle(): var {
        toggleCount += 1;
        openHostCount = openHostCount === 0 ? 1 : 0;
        revision += 1;
        return Object.freeze({
            "accepted": true,
            "changed": true,
            "errorCode": "",
            "revision": revision
        });
    }
}
