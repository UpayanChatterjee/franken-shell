import QtQuick
import Quickshell

Scope {
    id: root

    property int nextSequence: 1
    property var active: root._snapshot([], root.nextSequence)

    signal activated(var snapshot)

    function replaceDefinitions(definitions) {
        root.nextSequence += 1;
        root.active = root._snapshot(definitions, root.nextSequence);
        root.activated(root.active);
    }

    function _snapshot(definitions, sequence: int) {
        const copied = JSON.parse(JSON.stringify(definitions));
        return {
            activationSequence: sequence,
            requestGeneration: sequence,
            commands: {
                definitions: {
                    toArray: () => JSON.parse(JSON.stringify(copied))
                }
            }
        };
    }
}
