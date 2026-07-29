import QtQuick

QtObject {
    property int closeCount: 0
    property int revision: 7

    function closeAll(reason: string): var {
        const changed = closeCount === 0;
        closeCount += 1;
        if (changed)
            revision += 1;
        return Object.freeze({
            "accepted": true,
            "changed": changed,
            "errorCode": "",
            "revision": revision,
            "reason": reason
        });
    }
}
