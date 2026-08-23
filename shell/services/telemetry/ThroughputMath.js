.pragma library

function parseNetworkCounters(text) {
    const counters = {};
    for (const rawLine of String(text ?? "").split("\n")) {
        const separator = rawLine.indexOf(":");
        if (separator < 0)
            continue;
        const name = rawLine.slice(0, separator).trim();
        if (name.length === 0 || name === "lo")
            continue;
        const fields = rawLine.slice(separator + 1).trim().split(/\s+/);
        if (fields.length < 16)
            continue;
        const received = Number(fields[0]);
        const transmitted = Number(fields[8]);
        if (!Number.isFinite(received) || !Number.isFinite(transmitted) || received < 0 || transmitted < 0)
            continue;
        counters[name] = Object.freeze({
            "received": received,
            "transmitted": transmitted
        });
    }
    return Object.freeze(counters);
}

function counterDelta(previous, current) {
    if (!Number.isFinite(previous) || !Number.isFinite(current) || previous < 0 || current < 0)
        return 0;
    if (current >= previous)
        return current - previous;
    const wrap32 = 4294967296;
    if (previous >= 4026531840 && current <= 268435455)
        return wrap32 - previous + current;
    return 0;
}

function rates(previous, current, elapsedMs) {
    if (!Number.isFinite(elapsedMs) || elapsedMs <= 0)
        return Object.freeze({
            "download": 0,
            "upload": 0,
            "sampledInterfaceCount": 0
        });
    let received = 0;
    let transmitted = 0;
    let sampled = 0;
    for (const name of Object.keys(current)) {
        if (!(name in previous))
            continue;
        received += counterDelta(previous[name].received, current[name].received);
        transmitted += counterDelta(previous[name].transmitted, current[name].transmitted);
        sampled += 1;
    }
    const seconds = elapsedMs / 1000;
    return Object.freeze({
        "download": received / seconds,
        "upload": transmitted / seconds,
        "sampledInterfaceCount": sampled
    });
}

function appendBounded(values, value, capacity) {
    const next = values.concat([Math.max(0, Number(value) || 0)]);
    return Object.freeze(next.slice(Math.max(0, next.length - Math.max(1, capacity))));
}

function average(values) {
    if (values.length === 0)
        return 0;
    return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function compactRate(bytesPerSecond, unit, base, zeroFormat) {
    let value = Math.max(0, Number(bytesPerSecond) || 0);
    if (unit === "bits")
        value *= 8;
    const radix = base === 1024 ? 1024 : 1000;
    if (value < radix)
        return value === 0 ? String(zeroFormat || "0K") : Math.round(value / radix) + "K";
    const suffixes = ["K", "M", "G", "T", "P", "E"];
    let suffixIndex = -1;
    while (value >= radix && suffixIndex < suffixes.length - 1) {
        value /= radix;
        suffixIndex += 1;
    }
    return Math.round(value) + suffixes[suffixIndex];
}

function tooltip(download, upload, unit, base) {
    const suffix = unit === "bits" ? "b/s" : "B/s";
    return "↓ " + compactRate(download, unit, base, "0K") + suffix + "  ↑ " + compactRate(upload, unit, base, "0K") + suffix;
}
