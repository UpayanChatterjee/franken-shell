import QtQuick

QtObject {
    property int focusCount: 0

    function requestKeyboardFocus(): var {
        focusCount += 1;
        return Object.freeze({
            "accepted": true,
            "errorCode": ""
        });
    }
}
