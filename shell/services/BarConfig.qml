pragma Singleton

import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property alias showCpu: adapter.showCpu
    property alias showRam: adapter.showRam
    property alias showUpload: adapter.showUpload
    property alias showDownload: adapter.showDownload
    property alias showLyrics: adapter.showLyrics

    FileView {
        path: `${Paths.config}/bar-extras.json`
        blockLoading: true
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property bool showCpu: true
            property bool showRam: true
            property bool showUpload: true
            property bool showDownload: true
            property bool showLyrics: true
        }
    }
}
