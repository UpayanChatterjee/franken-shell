import "../../theme/ThemeDefaults.js" as ThemeDefaults
import QtQuick
import Quickshell
import "../../surfaces" as Surfaces
import "../../theme" as Theme

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function clone(value): var {
        return JSON.parse(JSON.stringify(value));
    }
    function fail(message: string) {
        console.error("FAIL theme-manager:", message);
        Qt.exit(1);
    }
    function fixture(mode: string, highContrast: bool, reducedMotion: bool): var {
        return ThemeDefaults.create({
            "mode": mode,
            "highContrast": highContrast,
            "reducedMotion": reducedMotion,
            "fontFamily": "Sans Serif",
            "fontScale": 1.0
        });
    }
    function instantiateRepresentative(theme): bool {
        const surface = diagnosticSurfaceComponent.createObject(root, {
            "theme": theme
        });
        if (surface === null)
            return false;
        surface.destroy();
        return true;
    }
    function member(object, key: string): var {
        return object[key];
    }
    function run() {
        const fixtures = [root.fixture("dark", false, false), root.fixture("light", false, false), root.fixture("dark", true, false), root.fixture("light", true, true)];
        for (let index = 0; index < fixtures.length; ++index) {
            fixtures[index].id = "fixture.profile." + index;
            const result = themeManager.applyCandidate(fixtures[index], "fixture");
            root.check(result.accepted && result.changed, "fixture profile " + index + " activates");
            root.check(themeManager.activeId === "fixture.profile." + index, "fixture profile identity is atomic");
            root.check(root.instantiateRepresentative(themeManager.active), "diagnostic surface instantiates for fixture " + index);
        }
        const reducedMotion = themeManager.active.motion;
        root.check(themeManager.active.reducedMotion && root.member(reducedMotion, "durationFast") === 0 && root.member(reducedMotion, "durationSlow") === 0, "reduced-motion fixture disables nonessential durations");

        let candidate = root.fixture("dark", false, false);
        candidate.id = "fixture.valid";
        let result = themeManager.applyCandidate(candidate, "fixture");
        root.check(result.accepted, "complete semantic candidate activates");
        const retainedId = themeManager.activeId;
        const retainedRevision = themeManager.revision;
        candidate.colors.surfaceBase = "#FFFFFF";
        const activeColors = themeManager.active.colors;
        root.check(String(root.member(activeColors, "surfaceBase")).toLowerCase() !== "#ffffff", "active snapshot is detached from the candidate");

        candidate = root.fixture("dark", false, false);
        candidate.id = "fixture.missing";
        delete candidate.colors.textPrimary;
        result = themeManager.applyCandidate(candidate, "fixture");
        root.check(!result.accepted && result.errorCode === "THEME_COLOR_INVALID", "missing required colour is rejected");
        root.check(themeManager.activeId === retainedId && themeManager.revision === retainedRevision, "invalid candidate retains the complete last-valid theme");
        root.check(themeManager.health === "degraded", "rejected candidate degrades theme health");

        candidate = root.fixture("dark", false, false);
        candidate.id = "fixture.badType";
        candidate.spacing.space2 = "8";
        result = themeManager.applyCandidate(candidate, "fixture");
        root.check(!result.accepted && result.errorCode === "THEME_SPACING_INVALID", "invalid token type is rejected");

        candidate = root.fixture("dark", false, true);
        candidate.id = "fixture.badReducedMotion";
        candidate.motion.durationStandard = 200;
        result = themeManager.applyCandidate(candidate, "fixture");
        root.check(!result.accepted && result.errorCode === "THEME_MOTION_INVALID", "reduced-motion candidates cannot retain long motion");

        candidate = root.fixture("dark", false, false);
        candidate.id = "fixture.badContrast";
        candidate.colors.textPrimary = candidate.colors.surfaceBase;
        result = themeManager.applyCandidate(candidate, "fixture");
        root.check(!result.accepted && result.errorCode === "THEME_CONTRAST_INVALID", "unreadable colour pairing is rejected");

        candidate = root.fixture("light", false, false);
        candidate.id = "fixture.recovery";
        candidate.privatePalette = {
            "wallpaperPath": "/private/wallpaper"
        };
        result = themeManager.applyCandidate(candidate, "fixture");
        root.check(result.accepted && themeManager.health === "healthy" && themeManager.lastError === "", "later valid candidate recovers health");
        root.check(typeof root.member(themeManager.active, "privatePalette") === "undefined", "unapproved raw palette fields do not enter the semantic snapshot");

        for (let index = 0; index < 24; ++index) {
            candidate = root.fixture(index % 2 === 0 ? "dark" : "light", index % 3 === 0, index % 5 === 0);
            candidate.id = "fixture.rapid." + index;
            result = themeManager.applyCandidate(candidate, "fixture");
            root.check(result.accepted, "rapid candidate " + index + " is valid");
        }
        root.check(themeManager.activeId === "fixture.rapid.23" && themeManager.activeMode === "light", "rapid updates settle on one complete final snapshot");

        fakeConfigService.replace("light", "dark", true, true, "Fixture Sans", 1.25);
        configSettleTimer.start();
    }

    Component.onCompleted: startTimer.start()

    FakeThemeConfigService {
        id: fakeConfigService
    }
    Theme.ThemeManager {
        id: themeManager

        configService: fakeConfigService
    }
    Component {
        id: diagnosticSurfaceComponent

        Surfaces.DiagnosticSurface {
            mode: "theme-test"
            startupState: "OptionalIntegrationsReady"
            visible: false
        }
    }
    Timer {
        id: startTimer

        interval: 0

        onTriggered: root.run()
    }
    Timer {
        id: configSettleTimer

        interval: 0

        onTriggered: {
            root.check(themeManager.activeMode === "light", "configuration selects the built-in light fallback");
            root.check(themeManager.active.highContrast && themeManager.active.reducedMotion, "configuration accessibility overrides map through semantic tokens");
            const typography = themeManager.active.typography;
            root.check(root.member(typography, "fontFamily") === "Fixture Sans" && root.member(typography, "fontSizeBody") === 20, "configuration font family and scale apply atomically");
            root.check(themeManager.activeSource === "builtInFallback", "configuration fallback remains independent of optional dynamic-colour services");
            root.check(themeManager.summary().health === "healthy", "theme diagnostics report healthy active state");
            console.info("PASS theme-manager: semantic tokens, atomic retention, contrast, fixtures, and config mapping");
            exitTimer.start();
        }
    }
    Timer {
        id: exitTimer

        interval: 0

        onTriggered: Qt.quit()
    }
}
