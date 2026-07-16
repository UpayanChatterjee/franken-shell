.pragma library

function _trimTrailingSlashes(path) {
    let result = path;
    while (result.length > 1 && result.endsWith("/"))
        result = result.slice(0, -1);
    return result;
}

function resolve(xdgConfigHome, home, fixtureOverride, fixtureOverrideAllowed) {
    const override = String(fixtureOverride ?? "");
    if (fixtureOverrideAllowed === true && override.length > 0)
        return override;

    const xdg = String(xdgConfigHome ?? "");
    if (xdg.length > 0)
        return _trimTrailingSlashes(xdg) + "/franken-shell/config.toml";

    const homePath = String(home ?? "");
    if (homePath.length === 0)
        return "";
    return _trimTrailingSlashes(homePath) + "/.config/franken-shell/config.toml";
}

function watchAnchor(authoritativePath) {
    let path = _trimTrailingSlashes(String(authoritativePath ?? ""));
    const separator = path.lastIndexOf("/");
    if (separator < 0)
        return ".";
    return separator === 0 ? "/" : path.slice(0, separator);
}
