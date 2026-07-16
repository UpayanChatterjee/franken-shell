import QtQuick
import Quickshell

Scope {
    id: root

    required property var _source
    required property var _metadata
    readonly property int requestGeneration: snapshotStorage.metadata.requestGeneration
    readonly property string source: snapshotStorage.metadata.source
    readonly property string sourceState: snapshotStorage.metadata.sourceState
    readonly property bool migratedInMemory: snapshotStorage.metadata.migratedInMemory
    readonly property ConfigValueList
    warnings: ConfigValueList {
        _values: snapshotStorage.metadata.warnings
    }

    readonly property int activationSequence: snapshotStorage.metadata.activationSequence
    readonly property string activatedAt: snapshotStorage.metadata.activatedAt
    readonly property int schemaVersion: snapshotStorage.source.schemaVersion
    readonly property QtObject
    shell: QtObject {
        readonly property string language: snapshotStorage.source.shell.language
        readonly property string timeFormat: snapshotStorage.source.shell.timeFormat
        readonly property string firstDayOfWeek: snapshotStorage.source.shell.firstDayOfWeek
        readonly property QtObject
        startup: QtObject {
            readonly property bool showReadinessToast: snapshotStorage.source.shell.startup.showReadinessToast
            readonly property bool restoreSessionState: snapshotStorage.source.shell.startup.restoreSessionState
        }

        readonly property QtObject
        reload: QtObject {
            readonly property bool watchConfig: snapshotStorage.source.shell.reload.watchConfig
            readonly property int debounceMs: snapshotStorage.source.shell.reload.debounceMs
        }

    }

    readonly property QtObject
    appearance: QtObject {
        readonly property string mode: snapshotStorage.source.appearance.mode
        readonly property string fallbackMode: snapshotStorage.source.appearance.fallbackMode
        readonly property string iconTheme: snapshotStorage.source.appearance.iconTheme
        readonly property bool reducedMotion: snapshotStorage.source.appearance.reducedMotion
        readonly property bool highContrast: snapshotStorage.source.appearance.highContrast
        readonly property QtObject
        dynamicColors: QtObject {
            readonly property bool enabled: snapshotStorage.source.appearance.dynamicColors.enabled
            readonly property string source: snapshotStorage.source.appearance.dynamicColors.source
            readonly property bool transition: snapshotStorage.source.appearance.dynamicColors.transition
        }

        readonly property QtObject
        surfaceOpacity: QtObject {
            readonly property real bar: snapshotStorage.source.appearance.surfaceOpacity.bar
            readonly property real controlCenter: snapshotStorage.source.appearance.surfaceOpacity.controlCenter
            readonly property real popover: snapshotStorage.source.appearance.surfaceOpacity.popover
            readonly property real notification: snapshotStorage.source.appearance.surfaceOpacity.notification
        }

        readonly property QtObject
        blur: QtObject {
            readonly property bool enabled: snapshotStorage.source.appearance.blur.enabled
            readonly property bool popovers: snapshotStorage.source.appearance.blur.popovers
        }

        readonly property QtObject
        font: QtObject {
            readonly property string family: snapshotStorage.source.appearance.font.family
            readonly property real scale: snapshotStorage.source.appearance.font.scale
        }

    }

    readonly property QtObject
    bar: QtObject {
        readonly property bool enabled: snapshotStorage.source.bar.enabled
        readonly property string edge: snapshotStorage.source.bar.edge
        readonly property var thickness: snapshotStorage.source.bar.thickness
        readonly property string visibleOn: snapshotStorage.source.bar.visibleOn
        readonly property bool hideInFullscreen: snapshotStorage.source.bar.hideInFullscreen
        readonly property QtObject
        autohide: QtObject {
            readonly property bool enabled: snapshotStorage.source.bar.autohide.enabled
            readonly property int revealDelayMs: snapshotStorage.source.bar.autohide.revealDelayMs
            readonly property int hideDelayMs: snapshotStorage.source.bar.autohide.hideDelayMs
            readonly property real activationWidth: snapshotStorage.source.bar.autohide.activationWidth
            readonly property bool revealOverFullscreen: snapshotStorage.source.bar.autohide.revealOverFullscreen
        }

        readonly property QtObject
        layout: QtObject {
            readonly property ConfigValueList
            start: ConfigValueList {
                _values: snapshotStorage.source.bar.layout.start
            }

            readonly property ConfigValueList
            context: ConfigValueList {
                _values: snapshotStorage.source.bar.layout.context
            }

            readonly property ConfigValueList
            end: ConfigValueList {
                _values: snapshotStorage.source.bar.layout.end
            }

        }

        readonly property QtObject
        workspacePager: QtObject {
            readonly property int groupSize: snapshotStorage.source.bar.workspacePager.groupSize
            readonly property bool showOccupancy: snapshotStorage.source.bar.workspacePager.showOccupancy
            readonly property bool showApplicationIcons: snapshotStorage.source.bar.workspacePager.showApplicationIcons
            readonly property bool scrollEnabled: snapshotStorage.source.bar.workspacePager.scrollEnabled
            readonly property string scrollDirection: snapshotStorage.source.bar.workspacePager.scrollDirection
        }

        readonly property QtObject
        contextRegion: QtObject {
            readonly property int slots: snapshotStorage.source.bar.contextRegion.slots
            readonly property string overflow: snapshotStorage.source.bar.contextRegion.overflow
            readonly property ConfigValueList
            priority: ConfigValueList {
                _values: snapshotStorage.source.bar.contextRegion.priority
            }

        }

        readonly property QtObject
        networkSpeed: QtObject {
            readonly property bool enabled: snapshotStorage.source.bar.networkSpeed.enabled
            readonly property string show: snapshotStorage.source.bar.networkSpeed.show
            readonly property string unit: snapshotStorage.source.bar.networkSpeed.unit
            readonly property int base: snapshotStorage.source.bar.networkSpeed.base
            readonly property int decimals: snapshotStorage.source.bar.networkSpeed.decimals
            readonly property int updateIntervalMs: snapshotStorage.source.bar.networkSpeed.updateIntervalMs
            readonly property int smoothingWindow: snapshotStorage.source.bar.networkSpeed.smoothingWindow
            readonly property string zeroFormat: snapshotStorage.source.bar.networkSpeed.zeroFormat
        }

        readonly property QtObject
        battery: QtObject {
            readonly property bool showPercentSign: snapshotStorage.source.bar.battery.showPercentSign
            readonly property bool chargingAnimation: snapshotStorage.source.bar.battery.chargingAnimation
        }

        readonly property QtObject
        dateTime: QtObject {
            readonly property bool showDate: snapshotStorage.source.bar.dateTime.showDate
            readonly property string monthFormat: snapshotStorage.source.bar.dateTime.monthFormat
            readonly property string verticalLayout: snapshotStorage.source.bar.dateTime.verticalLayout
        }

        readonly property QtObject
        vicinae: QtObject {
            readonly property bool show: snapshotStorage.source.bar.vicinae.show
            readonly property string position: snapshotStorage.source.bar.vicinae.position
        }

    }

    readonly property QtObject
    controlCenter: QtObject {
        readonly property bool enabled: snapshotStorage.source.controlCenter.enabled
        readonly property string edge: snapshotStorage.source.controlCenter.edge
        readonly property var width: snapshotStorage.source.controlCenter.width
        readonly property string defaultPage: snapshotStorage.source.controlCenter.defaultPage
        readonly property int restoreLastPageForMs: snapshotStorage.source.controlCenter.restoreLastPageForMs
        readonly property ConfigValueList
        quickControls: ConfigValueList {
            _values: snapshotStorage.source.controlCenter.quickControls
        }

        readonly property ConfigValueList
        sliders: ConfigValueList {
            _values: snapshotStorage.source.controlCenter.sliders
        }

        readonly property ConfigValueList
        tabs: ConfigValueList {
            _values: snapshotStorage.source.controlCenter.tabs
        }

        readonly property QtObject
        edgeDrag: QtObject {
            readonly property bool enabled: snapshotStorage.source.controlCenter.edgeDrag.enabled
            readonly property real activationWidth: snapshotStorage.source.controlCenter.edgeDrag.activationWidth
            readonly property real minimumDistance: snapshotStorage.source.controlCenter.edgeDrag.minimumDistance
            readonly property real openThreshold: snapshotStorage.source.controlCenter.edgeDrag.openThreshold
            readonly property real velocityThreshold: snapshotStorage.source.controlCenter.edgeDrag.velocityThreshold
            readonly property real horizontalIntentRatio: snapshotStorage.source.controlCenter.edgeDrag.horizontalIntentRatio
            readonly property bool allowInFullscreen: snapshotStorage.source.controlCenter.edgeDrag.allowInFullscreen
        }

        readonly property QtObject
        scrim: QtObject {
            readonly property bool enabled: snapshotStorage.source.controlCenter.scrim.enabled
            readonly property bool dismissOnClick: snapshotStorage.source.controlCenter.scrim.dismissOnClick
        }

    }

    readonly property QtObject
    workspaces: QtObject {
        readonly property ConfigValueList
        special: ConfigValueList {
            _values: snapshotStorage.source.workspaces.special
        }

        readonly property QtObject
        numbered: QtObject {
            readonly property int minimum: snapshotStorage.source.workspaces.numbered.minimum
            readonly property int maximum: snapshotStorage.source.workspaces.numbered.maximum
            readonly property int groupSize: snapshotStorage.source.workspaces.numbered.groupSize
            readonly property bool wrap: snapshotStorage.source.workspaces.numbered.wrap
            readonly property ConfigValueMap
            semanticLabels: ConfigValueMap {
                _values: snapshotStorage.source.workspaces.numbered.semanticLabels
            }

        }

        readonly property QtObject
        overview: QtObject {
            readonly property string provider: snapshotStorage.source.workspaces.overview.provider
            readonly property bool openOnActiveWorkspaceClick: snapshotStorage.source.workspaces.overview.openOnActiveWorkspaceClick
            readonly property int rows: snapshotStorage.source.workspaces.overview.rows
            readonly property int columns: snapshotStorage.source.workspaces.overview.columns
            readonly property bool showSpecialWorkspaces: snapshotStorage.source.workspaces.overview.showSpecialWorkspaces
            readonly property bool hideEmptyRows: snapshotStorage.source.workspaces.overview.hideEmptyRows
        }

        readonly property QtObject
        focusedWindowActions: QtObject {
            readonly property bool enabled: snapshotStorage.source.workspaces.focusedWindowActions.enabled
            readonly property ConfigValueList
            actions: ConfigValueList {
                _values: snapshotStorage.source.workspaces.focusedWindowActions.actions
            }

        }

    }

    readonly property QtObject
    integrations: QtObject {
        readonly property QtObject
        caelestia: QtObject {
            readonly property bool enabled: snapshotStorage.source.integrations.caelestia.enabled
            readonly property bool dynamicColors: snapshotStorage.source.integrations.caelestia.dynamicColors
            readonly property ConfigValueList
            services: ConfigValueList {
                _values: snapshotStorage.source.integrations.caelestia.services
            }

        }

        readonly property QtObject
        vicinae: QtObject {
            readonly property bool enabled: snapshotStorage.source.integrations.vicinae.enabled
            readonly property bool required: snapshotStorage.source.integrations.vicinae.required
            readonly property bool themeSync: snapshotStorage.source.integrations.vicinae.themeSync
            readonly property bool extensionEnabled: snapshotStorage.source.integrations.vicinae.extensionEnabled
            readonly property ConfigValueList
            shortcutMenu: ConfigValueList {
                _values: snapshotStorage.source.integrations.vicinae.shortcutMenu
            }

        }

        readonly property QtObject
        overview: QtObject {
            readonly property bool enabled: snapshotStorage.source.integrations.overview.enabled
            readonly property string provider: snapshotStorage.source.integrations.overview.provider
            readonly property bool required: snapshotStorage.source.integrations.overview.required
            readonly property string instanceName: snapshotStorage.source.integrations.overview.instanceName
            readonly property bool themeSync: snapshotStorage.source.integrations.overview.themeSync
            readonly property bool configSync: snapshotStorage.source.integrations.overview.configSync
        }

        readonly property QtObject
        autoCpuFreq: QtObject {
            readonly property bool enabled: snapshotStorage.source.integrations.autoCpuFreq.enabled
            readonly property bool required: snapshotStorage.source.integrations.autoCpuFreq.required
        }

    }

    readonly property QtObject
    commands: QtObject {
        readonly property ConfigValueList
        ids: ConfigValueList {
            _values: snapshotStorage.source.commands.ids
        }

        readonly property ConfigValueList
        definitions: ConfigValueList {
            _values: snapshotStorage.source.commands.definitions
        }

        readonly property var byId: (id) => {
            for (let index = 0; index < definitions.count; ++index) {
                const definition = definitions.at(index);
                if (definition.id === id)
                    return definition;

            }
            return null;
        }
    }

    Component.onCompleted: {
        snapshotStorage.source = root._source;
        snapshotStorage.metadata = root._metadata;
        root._source = null;
        root._metadata = null;
    }

    QtObject {
        id: snapshotStorage

        property var source: root._source
        property var metadata: root._metadata
    }

}
