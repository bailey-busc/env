pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Singleton {
    id: root

    Connections {
        function notification(notification: Notification): void {
        }

        target: NotificationServer
    }
}
