.pragma library

function definitions() {
    return Object.freeze([definition("call", "phone-incoming-call"), definition("alarm", "alarm-clock-elapsed"), definition("timer", "alarm-clock-elapsed"), definition("critical", "dialog-warning")]);
}

function definition(kind, eventId) {
    return Object.freeze({
        id: "notification.sound." + kind,
        executable: "canberra-gtk-play",
        arguments: Object.freeze(["--id", eventId, "--description", "Franken Shell " + kind + " alert"]),
        timeoutMs: 5000,
        runtimeArgumentPolicy: "none"
    });
}
