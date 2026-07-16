import QtQuick
import Quickshell

Scope {
    id: root

    required property var _values
    readonly property int count: listStorage.values.length
    readonly property var at: (index) => {
        if (index < 0 || index >= listStorage.values.length)
            return null;

        return JSON.parse(JSON.stringify(listStorage.values[index]));
    }
    readonly property var toArray: () => {
        return JSON.parse(JSON.stringify(listStorage.values));
    }

    function contains(value) : bool {
        return listStorage.values.indexOf(value) !== -1;
    }

    Component.onCompleted: {
        listStorage.values = root._values;
        root._values = null;
    }

    QtObject {
        id: listStorage

        property var values: root._values
    }

}
