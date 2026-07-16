.pragma library

function _string(value) {
    return value === null || value === undefined ? "" : String(value);
}

function _number(value, fallback) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function _positive(value, fallback) {
    const parsed = _number(value, fallback);
    return parsed > 0 ? parsed : fallback;
}

function _same(a, b) {
    return a !== null && a !== undefined && b !== null && b !== undefined && a === b;
}

function _transform(code) {
    const normalized = Math.max(0, Math.min(7, Math.trunc(_number(code, 0))));
    const names = [
        "normal",
        "rotate90CounterClockwise",
        "rotate180",
        "rotate270CounterClockwise",
        "flipped",
        "flipped90CounterClockwise",
        "flipped180",
        "flipped270CounterClockwise"
    ];
    return {
        code: normalized,
        name: names[normalized],
        flipped: normalized >= 4,
        swapsAxes: normalized === 1 || normalized === 3 || normalized === 5 || normalized === 7
    };
}

function _geometry(x, y, width, height, coordinateSpace) {
    return {
        x: Math.round(_number(x, 0)),
        y: Math.round(_number(y, 0)),
        width: Math.max(0, Math.round(_number(width, 0))),
        height: Math.max(0, Math.round(_number(height, 0))),
        coordinateSpace: coordinateSpace
    };
}

function _screenFacts(screen) {
    return {
        ref: screen.ref ?? null,
        mappedMonitorRef: screen.mappedMonitorRef ?? null,
        connector: _string(screen.name),
        model: _string(screen.model),
        serial: _string(screen.serialNumber),
        geometry: _geometry(screen.x, screen.y, screen.width, screen.height, "qtDeviceIndependentPixels"),
        devicePixelRatio: _positive(screen.devicePixelRatio, 1),
        qtOrientation: _string(screen.orientation)
    };
}

function _monitorFacts(monitor) {
    const raw = monitor.raw ?? {};
    const transform = _transform(raw.transform ?? monitor.transform);
    const scale = _positive(monitor.scale ?? raw.scale, 1);
    const physicalWidth = Math.max(0, Math.round(_number(monitor.width ?? raw.width, 0)));
    const physicalHeight = Math.max(0, Math.round(_number(monitor.height ?? raw.height, 0)));
    const orientedWidth = transform.swapsAxes ? physicalHeight : physicalWidth;
    const orientedHeight = transform.swapsAxes ? physicalWidth : physicalHeight;
    const activeWorkspace = monitor.activeWorkspace ?? {};

    return {
        ref: monitor.ref ?? null,
        backendId: _number(monitor.id ?? raw.id, -1),
        connector: _string(monitor.name ?? raw.name),
        description: _string(monitor.description ?? raw.description),
        make: _string(raw.make ?? monitor.make),
        model: _string(raw.model ?? monitor.model),
        serial: _string(raw.serial ?? monitor.serial),
        scale: scale,
        transform: transform,
        compositorGeometry: _geometry(
            monitor.x ?? raw.x,
            monitor.y ?? raw.y,
            orientedWidth / scale,
            orientedHeight / scale,
            "hyprlandLogicalCoordinates"
        ),
        physicalModeDimensions: {
            width: physicalWidth,
            height: physicalHeight,
            coordinateSpace: "monitorModePixels"
        },
        focused: Boolean(monitor.focused),
        activeWorkspaceId: _number(activeWorkspace.id, -1),
        fullscreenActive: activeWorkspace.hasFullscreen === true,
        primary: raw.primary === true
    };
}

function _identityKeys(screen, monitor) {
    const serial = screen?.serial || monitor?.serial || "";
    const model = screen?.model || monitor?.model || "";
    const make = monitor?.make || "";
    const keys = [];

    if (serial.length > 0)
        keys.push("serial:" + serial + "|model:" + model + "|make:" + make);
    return keys;
}

function _geometryMatches(screen, monitor) {
    const a = screen.geometry;
    const b = monitor.compositorGeometry;
    return Math.abs(a.x - b.x) <= 1
        && Math.abs(a.y - b.y) <= 1
        && Math.abs(a.width - b.width) <= 1
        && Math.abs(a.height - b.height) <= 1;
}

function _metadataScore(screen, monitor) {
    let score = 0;
    if (screen.serial.length > 0 && monitor.serial.length > 0) {
        if (screen.serial !== monitor.serial)
            return -1;
        score += 8;
    }
    if (screen.model.length > 0 && monitor.model.length > 0) {
        if (screen.model !== monitor.model)
            return -1;
        score += 4;
    }
    if (screen.connector.length > 0 && screen.connector === monitor.connector)
        score += 2;
    return score;
}

function _configurationFor(connector, model, serial, description, make, configuration) {
    const result = {
        configured: true,
        barEnabled: configuration.barEnabled !== false,
        configuredBarEdge: configuration.barEdge || "left",
        primary: false
    };
    const monitorDefault = configuration._provisionalMonitorDefault ?? {};
    const defaultBar = monitorDefault.bar ?? {};
    if (typeof defaultBar.enabled === "boolean")
        result.barEnabled = defaultBar.enabled;
    if (typeof defaultBar.edge === "string" && defaultBar.edge.length > 0)
        result.configuredBarEdge = defaultBar.edge;

    // Private compatibility bridge for the documented future ConfigService
    // monitor schema. It is not a public mutable registry input.
    const rules = Array.isArray(configuration._provisionalMonitorRules)
        ? configuration._provisionalMonitorRules : [];

    for (const rule of rules) {
        const match = rule?.match ?? {};
        const matches = (!match.name || match.name === connector)
            && (!match.model || match.model === model)
            && (!match.serial || match.serial === serial)
            && (!match.description || match.description === description)
            && (!match.make || match.make === make);
        if (!matches)
            continue;
        const bar = rule.bar ?? {};
        if (typeof bar.enabled === "boolean")
            result.barEnabled = bar.enabled;
        if (typeof bar.edge === "string" && bar.edge.length > 0)
            result.configuredBarEdge = bar.edge;
        break;
    }
    return result;
}

function _record(screen, monitor, mappingHealth, configuration) {
    const connector = screen?.connector || monitor?.connector || "";
    const model = screen?.model || monitor?.model || "";
    const serial = screen?.serial || monitor?.serial || "";
    const logicalGeometry = screen?.geometry || monitor?.compositorGeometry
        || _geometry(0, 0, 0, 0, "unknown");
    const compositorGeometry = monitor?.compositorGeometry || null;
    const transform = monitor?.transform || _transform(0);
    const config = _configurationFor(
        connector,
        model,
        serial,
        monitor?.description || "",
        monitor?.make || "",
        configuration
    );
    const orientation = logicalGeometry.width === logicalGeometry.height
        ? "square"
        : logicalGeometry.width > logicalGeometry.height ? "landscape" : "portrait";

    return {
        _screenRef: screen?.ref ?? null,
        _hyprlandRef: monitor?.ref ?? null,
        _backendId: monitor?.backendId ?? -1,
        _identityKeys: _identityKeys(screen, monitor),
        connector: connector,
        make: monitor?.make || "",
        model: model,
        serial: serial,
        description: monitor?.description || model,
        logicalGeometry: logicalGeometry,
        compositorGeometry: compositorGeometry,
        physicalModeDimensions: monitor?.physicalModeDimensions || null,
        scale: monitor?.scale || screen?.devicePixelRatio || 1,
        devicePixelRatio: screen?.devicePixelRatio || monitor?.scale || 1,
        transformCode: transform.code,
        transform: transform.name,
        transformFlipped: transform.flipped,
        orientation: orientation,
        focused: monitor?.focused === true,
        focusedWindowMonitor: false,
        activeWorkspaceId: monitor?.activeWorkspaceId ?? -1,
        fullscreenActive: monitor?.fullscreenActive === true,
        fallbackRank: config.primary || monitor?.primary ? 0
            : config.configured && mappingHealth === "mapped" ? 100
            : config.configured ? 200 : 300,
        configured: config.configured,
        barEnabled: config.barEnabled,
        configuredBarEdge: config.configuredBarEdge,
        mappingHealth: mappingHealth,
        connected: true
    };
}

function normalize(snapshot, configuration) {
    const screens = (snapshot.screens ?? []).map(_screenFacts);
    const monitors = (snapshot.hyprlandMonitors ?? []).map(_monitorFacts);
    const usedMonitors = new Set();
    const records = [];
    const mappingErrors = [];

    for (const screen of screens) {
        let candidates = [];
        let ambiguous = false;

        if (screen.mappedMonitorRef !== null) {
            candidates = monitors.map((monitor, index) => ({ monitor, index }))
                .filter(entry => !usedMonitors.has(entry.index)
                    && _same(entry.monitor.ref, screen.mappedMonitorRef));
        }

        const sameNameScreens = screens.filter(candidate => candidate.connector === screen.connector);
        const sameNameMonitors = monitors.map((monitor, index) => ({ monitor, index }))
            .filter(entry => !usedMonitors.has(entry.index)
                && screen.connector.length > 0
                && entry.monitor.connector === screen.connector);

        if (candidates.length !== 1 || sameNameScreens.length > 1 || sameNameMonitors.length > 1)
            candidates = [];
        if (sameNameScreens.length === 1 && sameNameMonitors.length === 1)
            candidates = sameNameMonitors;

        if (candidates.length !== 1) {
            const metadata = monitors.map((monitor, index) => ({
                monitor: monitor,
                index: index,
                score: usedMonitors.has(index) ? -1 : _metadataScore(screen, monitor)
            })).filter(entry => entry.score >= 4);
            const bestScore = metadata.reduce((best, entry) => Math.max(best, entry.score), -1);
            const best = metadata.filter(entry => entry.score === bestScore);
            if (best.length === 1)
                candidates = best;
            else if (best.length > 1)
                ambiguous = true;
        }

        if (candidates.length !== 1 && !ambiguous) {
            const geometry = monitors.map((monitor, index) => ({ monitor, index }))
                .filter(entry => !usedMonitors.has(entry.index)
                    && _geometryMatches(screen, entry.monitor));
            if (geometry.length === 1)
                candidates = geometry;
            else if (geometry.length > 1)
                ambiguous = true;
        }

        if (candidates.length === 1) {
            usedMonitors.add(candidates[0].index);
            records.push(_record(screen, candidates[0].monitor, "mapped", configuration));
        } else {
            const health = ambiguous || sameNameMonitors.length > 1 ? "ambiguous" : "screenOnly";
            records.push(_record(screen, null, health, configuration));
            mappingErrors.push(health === "ambiguous" ? "ambiguousMapping" : "missingHyprlandMonitor");
        }
    }

    monitors.forEach((monitor, index) => {
        if (usedMonitors.has(index))
            return;
        records.push(_record(null, monitor, "hyprlandOnly", configuration));
        mappingErrors.push("missingQtScreen");
    });

    const focusedRef = snapshot.focusedMonitorRef ?? null;
    const focusedId = _number(snapshot.focusedMonitorId, -1);
    const focusedName = _string(snapshot.focusedMonitorName);
    const windowRef = snapshot.focusedWindowMonitorRef ?? null;
    const windowId = _number(snapshot.focusedWindowMonitorId, -1);
    const windowName = _string(snapshot.focusedWindowMonitorName);
    const focusedNameIsFallback = focusedRef === null && focusedId < 0;
    const windowNameIsFallback = windowRef === null && windowId < 0;

    for (const record of records) {
        if (_same(record._hyprlandRef, focusedRef)
            || focusedId >= 0 && record._backendId === focusedId
            || focusedNameIsFallback && focusedName.length > 0
                && record.connector === focusedName)
            record.focused = true;
        record.focusedWindowMonitor = _same(record._hyprlandRef, windowRef)
            || windowId >= 0 && record._backendId === windowId
            || windowNameIsFallback && windowName.length > 0
                && record.connector === windowName;
    }
    if (monitors.length > 0 && !records.some(record => record.focused))
        mappingErrors.push("focusedMonitorUnavailable");

    return {
        records: records,
        mappingErrors: Array.from(new Set(mappingErrors))
    };
}

function transformForCode(code) {
    return _transform(code);
}
