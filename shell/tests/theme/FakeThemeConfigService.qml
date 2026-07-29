import QtQuick

QtObject {
    id: root

    property var active: root.snapshot("dynamic", "dark", false, false, "system", 1.0)

    signal activated(var snapshot)

    function replace(mode: string, fallbackMode: string, highContrast: bool, reducedMotion: bool, fontFamily: string, fontScale: real) {
        root.active = root.snapshot(mode, fallbackMode, highContrast, reducedMotion, fontFamily, fontScale);
        root.activated(root.active);
    }
    function snapshot(mode: string, fallbackMode: string, highContrast: bool, reducedMotion: bool, fontFamily: string, fontScale: real): var {
        return {
            "appearance": {
                "mode": mode,
                "fallbackMode": fallbackMode,
                "highContrast": highContrast,
                "reducedMotion": reducedMotion,
                "font": {
                    "family": fontFamily,
                    "scale": fontScale
                },
                "surfaceOpacity": {
                    "bar": 0.96,
                    "controlCenter": 0.98,
                    "popover": 0.98,
                    "notification": 0.98
                }
            }
        };
    }
}
