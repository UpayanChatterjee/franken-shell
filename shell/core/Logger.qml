pragma Singleton

import QtQuick
import Quickshell

Scope {
    function write(level, domain, event, fields) {
        const payload = JSON.stringify({
            timestamp: new Date().toISOString(),
            level: level,
            domain: domain,
            event: event,
            fields: fields ?? {}
        });
        const category = domain === "config" ? configCategory
            : domain === "theme" ? themeCategory
            : domain === "surfaces" ? surfacesCategory
            : domain === "monitors" ? monitorsCategory
            : domain === "commands" ? commandsCategory
            : coreCategory;

        if (level === "debug")
            console.debug(category, payload);
        else if (level === "warning")
            console.warn(category, payload);
        else if (level === "error")
            console.error(category, payload);
        else
            console.info(category, payload);
    }

    function debug(domain, event, fields) {
        write("debug", domain, event, fields);
    }

    function info(domain, event, fields) {
        write("info", domain, event, fields);
    }

    function warning(domain, event, fields) {
        write("warning", domain, event, fields);
    }

    function error(domain, event, fields) {
        write("error", domain, event, fields);
    }

    LoggingCategory {
        id: coreCategory

        name: "franken.core"
        defaultLogLevel: LoggingCategory.Info
    }

    LoggingCategory {
        id: configCategory

        name: "franken.config"
        defaultLogLevel: LoggingCategory.Info
    }

    LoggingCategory {
        id: themeCategory

        name: "franken.theme"
        defaultLogLevel: LoggingCategory.Info
    }

    LoggingCategory {
        id: monitorsCategory

        name: "franken.monitors"
        defaultLogLevel: LoggingCategory.Info
    }

    LoggingCategory {
        id: commandsCategory

        name: "franken.commands"
        defaultLogLevel: LoggingCategory.Info
    }

    LoggingCategory {
        id: surfacesCategory

        name: "franken.surfaces"
        defaultLogLevel: LoggingCategory.Info
    }
}
