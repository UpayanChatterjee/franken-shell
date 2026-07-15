pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "arrow_upward"
            color: Colours.palette.m3tertiary
        }

        StyledText {
            text: {
                const fmt = NetworkUsage.formatBytes(NetworkUsage.uploadSpeed ?? 0);
                return fmt ? qsTr("Upload: %1 %2").arg(fmt.value.toFixed(1)).arg(fmt.unit) : qsTr("Upload: 0.0 B/s");
            }
        }
    }

    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "arrow_downward"
            color: Colours.palette.m3secondary
        }

        StyledText {
            text: {
                const fmt = NetworkUsage.formatBytes(NetworkUsage.downloadSpeed ?? 0);
                return fmt ? qsTr("Download: %1 %2").arg(fmt.value.toFixed(1)).arg(fmt.unit) : qsTr("Download: 0.0 B/s");
            }
        }
    }

    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "history"
            color: Colours.palette.m3outline
        }

        StyledText {
            text: {
                const down = NetworkUsage.formatBytesTotal(NetworkUsage.downloadTotal ?? 0);
                const up = NetworkUsage.formatBytesTotal(NetworkUsage.uploadTotal ?? 0);
                return (down && up) ? qsTr("Session — ↓%1 %2 ↑%3 %4").arg(down.value.toFixed(1)).arg(down.unit).arg(up.value.toFixed(1)).arg(up.unit) : qsTr("Session — 0.0 B");
            }
        }
    }
}
