import QtQuick
import Quickshell

Scope {
    id: root

    required property var _values
    readonly property ConfigValueList
    keys: ConfigValueList {
        _values: Object.keys(mapStorage.values)
    }

    readonly property var value: (key, fallback) => {
        if (!(key in mapStorage.values))
            return fallback;

        return JSON.parse(JSON.stringify(mapStorage.values[key]));
    }
    readonly property var toObject: () => {
        return JSON.parse(JSON.stringify(mapStorage.values));
    }

    Component.onCompleted: {
        mapStorage.values = root._values;
        root._values = null;
    }

    QtObject {
        id: mapStorage

        property var values: root._values
    }

}
