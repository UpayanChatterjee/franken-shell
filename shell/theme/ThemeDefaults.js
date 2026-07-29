.pragma library

function create(options) {
    const mode = options.mode === "light" ? "light" : "dark";
    const highContrast = options.highContrast === true;
    const reducedMotion = options.reducedMotion === true;
    const colors = mode === "light" ? lightColors(highContrast) : darkColors(highContrast);
    const fontScale = typeof options.fontScale === "number" ? options.fontScale : 1.0;

    return {
        "id": "builtIn." + mode + "." + (highContrast ? "highContrast" : "standard") + "." + (reducedMotion ? "reducedMotion" : "motion"),
        "mode": mode,
        "highContrast": highContrast,
        "reducedMotion": reducedMotion,
        "colors": colors,
        "typography": {
            "fontFamily": typeof options.fontFamily === "string" && options.fontFamily.length > 0 ? options.fontFamily : "Sans Serif",
            "fontSizeMetricSmall": scaled(12, fontScale),
            "fontSizeMetric": scaled(14, fontScale),
            "fontSizeLabel": scaled(14, fontScale),
            "fontSizeBody": scaled(16, fontScale),
            "fontSizeSection": scaled(18, fontScale),
            "fontSizeTitle": scaled(20, fontScale),
            "fontWeightRegular": 400,
            "fontWeightMedium": 500,
            "fontWeightSemibold": 600
        },
        "spacing": {
            "space1": 4,
            "space2": 8,
            "space3": 12,
            "space4": 16,
            "space5": 20,
            "space6": 24,
            "space8": 32
        },
        "radius": {
            "radiusSmall": 6,
            "radiusMedium": 10,
            "radiusLarge": 16,
            "radiusFull": 999
        },
        "motion": {
            "durationInstant": 0,
            "durationFast": reducedMotion ? 0 : 120,
            "durationStandard": reducedMotion ? 0 : 200,
            "durationSlow": reducedMotion ? 0 : 320,
            "easingStandard": "InOutCubic",
            "easingEmphasized": "OutBack",
            "easingDecelerate": "OutCubic",
            "easingAccelerate": "InCubic"
        },
        "opacity": {
            "bar": opacity(options.barOpacity, 0.96),
            "controlCenter": opacity(options.controlCenterOpacity, 0.98),
            "popover": opacity(options.popoverOpacity, 0.98),
            "notification": opacity(options.notificationOpacity, 0.98)
        },
        "metrics": {
            "barThickness": 48,
            "barItemExtent": 40,
            "controlCenterWidth": 400,
            "popoverMaxWidth": 440,
            "notificationWidth": 380,
            "iconSmall": 16,
            "iconMedium": 20,
            "iconLarge": 28,
            "focusRingWidth": highContrast ? 3 : 2,
            "outlineWidth": highContrast ? 2 : 1
        }
    };
}

function darkColors(highContrast) {
    return {
        "surfaceBase": highContrast ? "#08090B" : "#16181D",
        "surfaceRaised": highContrast ? "#111318" : "#22252C",
        "surfaceOverlay": highContrast ? "#181B21" : "#2B2F38",
        "surfacePopup": highContrast ? "#1D2027" : "#30343D",
        "surfaceScrim": "#99000000",
        "textPrimary": "#F7F8FA",
        "textSecondary": highContrast ? "#E1E4EA" : "#B8BEC9",
        "textDisabled": highContrast ? "#AEB4BF" : "#89919F",
        "textOnAccent": "#091529",
        "accentPrimary": highContrast ? "#BBD4FF" : "#8AB4F8",
        "accentContainer": highContrast ? "#315078" : "#263D60",
        "accentOnContainer": "#F0F5FF",
        "outlineSubtle": highContrast ? "#788291" : "#3B404B",
        "outlineStrong": highContrast ? "#C9D0DA" : "#7A8391",
        "outlineFocus": highContrast ? "#FFFFFF" : "#AFCBFF",
        "success": highContrast ? "#9CF2BA" : "#74D69C",
        "warning": highContrast ? "#FFE09A" : "#F4C56A",
        "critical": highContrast ? "#FFB4AB" : "#FF8A80",
        "privacy": highContrast ? "#E8C6FF" : "#D7A7FF"
    };
}

function lightColors(highContrast) {
    return {
        "surfaceBase": highContrast ? "#FFFFFF" : "#F7F8FC",
        "surfaceRaised": "#FFFFFF",
        "surfaceOverlay": highContrast ? "#E9ECF2" : "#EEF0F6",
        "surfacePopup": "#FFFFFF",
        "surfaceScrim": "#66000000",
        "textPrimary": highContrast ? "#000000" : "#1A1C22",
        "textSecondary": highContrast ? "#252A32" : "#4F5663",
        "textDisabled": highContrast ? "#4A515D" : "#707887",
        "textOnAccent": "#FFFFFF",
        "accentPrimary": highContrast ? "#173F78" : "#315F9D",
        "accentContainer": highContrast ? "#C6DAFF" : "#D8E6FF",
        "accentOnContainer": highContrast ? "#071A35" : "#153359",
        "outlineSubtle": highContrast ? "#6A7280" : "#D3D7E0",
        "outlineStrong": highContrast ? "#303640" : "#727A87",
        "outlineFocus": highContrast ? "#082E65" : "#244F8B",
        "success": highContrast ? "#0B542A" : "#176C3A",
        "warning": highContrast ? "#5C3900" : "#7A4E00",
        "critical": highContrast ? "#7F1717" : "#A32F2B",
        "privacy": highContrast ? "#51266D" : "#6E3A8D"
    };
}

function opacity(value, fallback) {
    return typeof value === "number" ? value : fallback;
}

function scaled(value, scale) {
    return Math.round(value * scale * 10) / 10;
}
