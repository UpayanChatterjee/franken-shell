.pragma library

const stringType = "string";
const booleanType = "boolean";
const numberType = "number";
const integerType = "integer";
const nullableStringType = "nullableString";
const autoOrNumberType = "autoOrNumber";

const stringArray = ["array", stringType];
const specialWorkspace = {
    id: stringType,
    hyprlandName: stringType,
    label: stringType,
    icon: stringType,
    shortcutHint: nullableStringType,
    defaultApplication: nullableStringType
};
const commandDefinition = {
    executable: stringType,
    arguments: stringArray,
    detached: booleanType,
    timeoutMs: integerType,
    environment: ["map", stringType]
};
const configurationShape = {
    schemaVersion: integerType,
    shell: {
        language: stringType,
        timeFormat: stringType,
        firstDayOfWeek: stringType,
        startup: {
            showReadinessToast: booleanType,
            restoreSessionState: booleanType
        },
        reload: {
            watchConfig: booleanType,
            debounceMs: integerType
        }
    },
    appearance: {
        mode: stringType,
        fallbackMode: stringType,
        iconTheme: stringType,
        reducedMotion: booleanType,
        highContrast: booleanType,
        dynamicColors: {
            enabled: booleanType,
            source: stringType,
            transition: booleanType
        },
        surfaceOpacity: {
            bar: numberType,
            controlCenter: numberType,
            popover: numberType,
            notification: numberType
        },
        blur: {
            enabled: booleanType,
            popovers: booleanType
        },
        font: {
            family: stringType,
            scale: numberType
        }
    },
    bar: {
        enabled: booleanType,
        edge: stringType,
        thickness: autoOrNumberType,
        visibleOn: stringType,
        hideInFullscreen: booleanType,
        autohide: {
            enabled: booleanType,
            revealDelayMs: integerType,
            hideDelayMs: integerType,
            activationWidth: numberType,
            revealOverFullscreen: booleanType
        },
        layout: {
            start: stringArray,
            context: stringArray,
            end: stringArray
        },
        workspacePager: {
            groupSize: integerType,
            showOccupancy: booleanType,
            showApplicationIcons: booleanType,
            scrollEnabled: booleanType,
            scrollDirection: stringType
        },
        contextRegion: {
            slots: integerType,
            overflow: stringType,
            priority: stringArray
        },
        networkSpeed: {
            enabled: booleanType,
            show: stringType,
            unit: stringType,
            base: integerType,
            decimals: integerType,
            updateIntervalMs: integerType,
            smoothingWindow: integerType,
            zeroFormat: stringType
        },
        battery: {
            showPercentSign: booleanType,
            chargingAnimation: booleanType
        },
        dateTime: {
            showDate: booleanType,
            monthFormat: stringType,
            verticalLayout: stringType
        },
        vicinae: {
            show: booleanType,
            position: stringType
        }
    },
    controlCenter: {
        enabled: booleanType,
        edge: stringType,
        width: autoOrNumberType,
        defaultPage: stringType,
        restoreLastPageForMs: integerType,
        quickControls: stringArray,
        sliders: stringArray,
        tabs: stringArray,
        edgeDrag: {
            enabled: booleanType,
            activationWidth: numberType,
            minimumDistance: numberType,
            openThreshold: numberType,
            velocityThreshold: numberType,
            horizontalIntentRatio: numberType,
            allowInFullscreen: booleanType
        },
        scrim: {
            enabled: booleanType,
            dismissOnClick: booleanType
        }
    },
    workspaces: {
        special: ["array", specialWorkspace],
        numbered: {
            minimum: integerType,
            maximum: integerType,
            groupSize: integerType,
            wrap: booleanType,
            semanticLabels: ["map", stringType]
        },
        overview: {
            provider: stringType,
            openOnActiveWorkspaceClick: booleanType,
            rows: integerType,
            columns: integerType,
            showSpecialWorkspaces: booleanType,
            hideEmptyRows: booleanType
        },
        focusedWindowActions: {
            enabled: booleanType,
            actions: stringArray
        }
    },
    integrations: {
        caelestia: {
            enabled: booleanType,
            dynamicColors: booleanType,
            services: stringArray
        },
        vicinae: {
            enabled: booleanType,
            required: booleanType,
            themeSync: booleanType,
            extensionEnabled: booleanType,
            shortcutMenu: stringArray
        },
        overview: {
            enabled: booleanType,
            provider: stringType,
            required: booleanType,
            instanceName: stringType,
            themeSync: booleanType,
            configSync: booleanType
        },
        autoCpuFreq: {
            enabled: booleanType,
            required: booleanType
        }
    },
    commands: ["commands", commandDefinition]
};

function build(normalized) {
    const projected = _project(normalized, configurationShape, "configuration");
    if (projected.schemaVersion !== 1)
        throw new Error("configuration.schemaVersion must equal 1");
    return deepFreeze(projected);
}

function sanitizeDiagnostics(diagnostics) {
    if (!Array.isArray(diagnostics))
        throw new Error("diagnostics must be an array");

    const result = [];
    for (let index = 0; index < diagnostics.length; ++index) {
        const item = diagnostics[index];
        if (!_isObject(item)
                || typeof item.severity !== "string"
                || typeof item.code !== "string"
                || typeof item.message !== "string"
                || typeof item.source !== "string") {
            throw new Error("diagnostic " + index + " is malformed");
        }
        result.push({
            severity: item.severity,
            code: item.code,
            message: item.message,
            configurationPath: item.configurationPath ?? null,
            source: item.source,
            line: item.line ?? null,
            column: item.column ?? null,
            repairHint: item.repairHint ?? null
        });
    }
    return deepFreeze(result);
}

function deepFreeze(value) {
    if (value === null || typeof value !== "object" || Object.isFrozen(value))
        return value;

    const keys = Object.keys(value);
    for (let index = 0; index < keys.length; ++index)
        deepFreeze(value[keys[index]]);
    return Object.freeze(value);
}

function _project(value, shape, path) {
    if (typeof shape === "string")
        return _projectScalar(value, shape, path);

    if (Array.isArray(shape)) {
        const kind = shape[0];
        if (kind === "array") {
            if (!Array.isArray(value))
                throw new Error(path + " must be an array");
            return value.map((item, index) => _project(item, shape[1], path + "[" + index + "]"));
        }
        if (kind === "map") {
            if (!_isObject(value))
                throw new Error(path + " must be an object map");
            const result = {};
            const keys = Object.keys(value).sort();
            for (let index = 0; index < keys.length; ++index) {
                const key = keys[index];
                result[key] = _project(value[key], shape[1], path + "." + key);
            }
            return result;
        }
        if (kind === "commands") {
            if (!_isObject(value))
                throw new Error(path + " must be an object map");
            const definitions = [];
            const keys = Object.keys(value).sort();
            for (let index = 0; index < keys.length; ++index) {
                const id = keys[index];
                const definition = _project(value[id], shape[1], path + "." + id);
                definition.id = id;
                definitions.push(definition);
            }
            return {
                definitions: definitions,
                ids: keys
            };
        }
        throw new Error("unsupported shape at " + path);
    }

    if (!_isObject(value))
        throw new Error(path + " must be an object");
    const result = {};
    const keys = Object.keys(shape);
    for (let index = 0; index < keys.length; ++index) {
        const key = keys[index];
        if (!(key in value))
            throw new Error(path + "." + key + " is missing");
        result[key] = _project(value[key], shape[key], path + "." + key);
    }
    return result;
}

function _projectScalar(value, type, path) {
    if (type === stringType && typeof value === "string")
        return value;
    if (type === booleanType && typeof value === "boolean")
        return value;
    if (type === numberType && typeof value === "number" && isFinite(value))
        return value;
    if (type === integerType
            && typeof value === "number"
            && isFinite(value)
            && value >= 0
            && Math.floor(value) === value) {
        return value;
    }
    if (type === nullableStringType
            && (value === null || typeof value === "string")) {
        return value;
    }
    if (type === autoOrNumberType
            && (value === "auto"
                || (typeof value === "number" && isFinite(value) && value > 0))) {
        return value;
    }
    throw new Error(path + " has an invalid " + type + " value");
}

function _isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}
