.pragma library

function parseMemory(text) {
    const values = {};
    for (const line of String(text ?? "").split("\n")) {
        const match = /^([A-Za-z_()]+):\s+(\d+)/.exec(line);
        if (match !== null)
            values[match[1]] = Number(match[2]) * 1024;
    }
    const total = Number(values.MemTotal ?? 0);
    const available = Number(values.MemAvailable ?? ((values.MemFree ?? 0) + (values.Buffers ?? 0) + (values.Cached ?? 0)));
    if (!Number.isFinite(total) || !Number.isFinite(available) || total <= 0 || available < 0)
        return null;
    const used = Math.max(0, Math.min(total, total - available));
    return Object.freeze({
        "total": total,
        "used": used,
        "available": Math.max(0, Math.min(total, available)),
        "percent": used / total * 100
    });
}

function parseCpu(text) {
    const line = String(text ?? "").split("\n").find(candidate => /^cpu\s/.test(candidate));
    if (line === undefined)
        return null;
    const values = line.trim().split(/\s+/).slice(1).map(Number);
    if (values.length < 4 || values.some(value => !Number.isFinite(value) || value < 0))
        return null;
    const total = values.reduce((sum, value) => sum + value, 0);
    const idle = values[3] + (values[4] ?? 0);
    return Object.freeze({
        "total": total,
        "idle": idle
    });
}

function cpuPercent(previous, current) {
    if (previous === null || current === null)
        return -1;
    const totalDelta = current.total - previous.total;
    const idleDelta = current.idle - previous.idle;
    if (totalDelta <= 0 || idleDelta < 0)
        return -1;
    return Math.max(0, Math.min(100, (totalDelta - idleDelta) / totalDelta * 100));
}

function parseStorage(text) {
    const lines = String(text ?? "").trim().split("\n").filter(line => line.trim().length > 0);
    for (let index = lines.length - 1; index >= 0; --index) {
        const fields = lines[index].trim().split(/\s+/);
        if (fields.length < 3)
            continue;
        const total = Number(fields[0]);
        const used = Number(fields[1]);
        if (!Number.isFinite(total) || !Number.isFinite(used) || total <= 0 || used < 0)
            continue;
        return Object.freeze({
            "mount": fields.slice(2).join(" "),
            "total": total,
            "used": Math.min(total, used),
            "percent": Math.min(total, used) / total * 100
        });
    }
    return null;
}

function formatBytes(bytes) {
    const value = Math.max(0, Number(bytes) || 0);
    const units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
    let scaled = value;
    let index = 0;
    while (scaled >= 1024 && index < units.length - 1) {
        scaled /= 1024;
        index += 1;
    }
    const precision = scaled >= 10 || index === 0 ? 0 : 1;
    return scaled.toFixed(precision) + " " + units[index];
}
