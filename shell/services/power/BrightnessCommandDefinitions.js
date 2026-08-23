.pragma library

function definitions() {
    return Object.freeze([Object.freeze({
            id: "brightness.discover",
            executable: "brightnessctl",
            arguments: Object.freeze(["--machine-readable", "--class", "backlight", "--list"]),
            timeoutMs: 2000,
            runtimeArgumentPolicy: "none",
            captureOutput: true,
            maximumOutputBytes: 65536
        }), Object.freeze({
            id: "brightness.set",
            executable: "brightnessctl",
            arguments: Object.freeze(["--machine-readable", "--device"]),
            timeoutMs: 2000,
            runtimeArgumentPolicy: "brightnessSet"
        })]);
}
