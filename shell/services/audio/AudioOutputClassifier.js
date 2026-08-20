.pragma library

function normalizedText(device) {
    const properties = device?.properties ?? {};
    return [device?.name, device?.description, device?.nickname, properties["device.form-factor"], properties["device.api"], properties["device.bus"], properties["media.class"], properties["api.alsa.path"], properties["api.bluez5.address"]].map(value => String(value ?? "").toLowerCase()).join(" ");
}

function classify(device) {
    if (device === null || device === undefined)
        return "unknown";

    const text = normalizedText(device);
    const bluetooth = /bluez|bluetooth/.test(text);
    if (bluetooth && /head(phone|set)|a2dp/.test(text))
        return "bluetoothHeadphones";
    if (/hdmi|displayport|display port/.test(text))
        return "hdmi";
    if (/headset/.test(text))
        return "headset";
    if (/headphone/.test(text))
        return "wiredHeadphones";
    if (/speaker/.test(text))
        return "speaker";
    if (/usb/.test(text) && /audio|dac/.test(text))
        return "usbDac";
    return "unknown";
}
