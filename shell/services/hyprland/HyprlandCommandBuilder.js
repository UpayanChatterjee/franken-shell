.pragma library

function result(accepted, request, errorCode) {
    return Object.freeze({
        accepted: accepted,
        request: request,
        errorCode: errorCode
    });
}

function failure(errorCode) {
    return result(false, "", errorCode);
}

function success(request) {
    return result(true, request, "");
}

function validWorkspaceNumber(number) {
    return Number.isInteger(number) && number > 0 && number <= 2147483647;
}

function validToken(value) {
    return typeof value === "string" && value.length > 0 && !/[\u0000-\u001f\u007f]/.test(value);
}

function validAddress(address) {
    return typeof address === "string" && /^0x[0-9a-fA-F]+$/.test(address);
}

function luaString(value) {
    return JSON.stringify(value);
}

function activateNumbered(number, usingLua) {
    if (!validWorkspaceNumber(number))
        return failure("HYPRLAND_INVALID_WORKSPACE");
    return success(usingLua ? "hl.dsp.focus({ workspace = " + luaString(String(number)) + " })" : "workspace " + number);
}

function toggleSpecial(name, usingLua) {
    if (!validToken(name))
        return failure("HYPRLAND_INVALID_SPECIAL_WORKSPACE");
    return success(usingLua ? "hl.dsp.workspace.toggle_special(" + luaString(name) + ")" : "togglespecialworkspace " + name);
}

function moveWindowToNumbered(number, follow, address, usingLua) {
    if (!validWorkspaceNumber(number))
        return failure("HYPRLAND_INVALID_WORKSPACE");
    if (!validAddress(address))
        return failure("HYPRLAND_INVALID_WINDOW_ADDRESS");
    return success(usingLua ? "hl.dsp.window.move({ workspace = " + luaString(String(number)) + ", follow = " + (follow ? "true" : "false") + ", window = " + luaString("address:" + address) + " })" : (follow ? "movetoworkspace " : "movetoworkspacesilent ") + number + ",address:" + address);
}

function moveWindowToSpecial(name, follow, address, usingLua) {
    if (!validToken(name))
        return failure("HYPRLAND_INVALID_SPECIAL_WORKSPACE");
    if (!validAddress(address))
        return failure("HYPRLAND_INVALID_WINDOW_ADDRESS");
    return success(usingLua ? "hl.dsp.window.move({ workspace = " + luaString("special:" + name) + ", follow = " + (follow ? "true" : "false") + ", window = " + luaString("address:" + address) + " })" : (follow ? "movetoworkspace " : "movetoworkspacesilent ") + "special:" + name + ",address:" + address);
}

function closeWindow(address, usingLua) {
    if (!validAddress(address))
        return failure("HYPRLAND_INVALID_WINDOW_ADDRESS");
    return success(usingLua ? "hl.dsp.window.close({ window = " + luaString("address:" + address) + " })" : "closewindow address:" + address);
}

function toggleFloating(address, usingLua) {
    if (!validAddress(address))
        return failure("HYPRLAND_INVALID_WINDOW_ADDRESS");
    return success(usingLua ? "hl.dsp.window.float({ action = \"toggle\", window = " + luaString("address:" + address) + " })" : "togglefloating address:" + address);
}

function toggleFullscreen(address, usingLua) {
    if (!validAddress(address))
        return failure("HYPRLAND_INVALID_WINDOW_ADDRESS");
    return success(usingLua ? "hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"toggle\", window = " + luaString("address:" + address) + " })" : "fullscreen 0");
}
