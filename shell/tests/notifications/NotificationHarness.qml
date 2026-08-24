import "../../services/notifications" as NotificationServices
import QtQuick
import Quickshell

Scope {
    id: root

    property alias history: history
    property alias policy: policy
    required property var runtime
    property alias service: service

    NotificationServices.NotificationPolicy {
        id: policy
    }
    NotificationServices.NotificationHistory {
        id: history
    }
    NotificationServices.NotificationService {
        id: service

        history: history
        policy: policy
        runtime: root.runtime
    }
}
