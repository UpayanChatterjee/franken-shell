import QtQuick
import Quickshell

Scope {
    id: root

    required property var adapter
    property real brightnessStep: 0.05
    property bool consumerActive: false
    readonly property var defaultTarget: root.adapter?.defaultTarget ?? null
    readonly property string lastError: root.adapter?.lastError ?? ""
    readonly property var operationTask: root.adapter?.operationTask ?? null
    readonly property var targets: root.adapter?.targets ?? Object.freeze([])
    readonly property real value: root.adapter?.value ?? 0
    readonly property bool visible: root.adapter?.available === true

    function adjustBySteps(steps: int): var {
        return root.setValue(root.value + steps * root.brightnessStep);
    }
    function setValue(value: real): var {
        return root.adapter.setValue(Math.max(0, Math.min(1, Number(value))));
    }

    Component.onCompleted: root.adapter.setConsumerActive(root.consumerActive)
    onConsumerActiveChanged: root.adapter.setConsumerActive(root.consumerActive)
}
