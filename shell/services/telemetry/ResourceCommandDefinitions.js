.pragma library

function definitions() {
    return Object.freeze([Object.freeze({
            id: "resource.storage-root",
            executable: "df",
            arguments: Object.freeze(["--block-size=1", "--output=size,used,target", "/"]),
            timeoutMs: 2000,
            runtimeArgumentPolicy: "none",
            captureOutput: true,
            maximumOutputBytes: 4096
        })]);
}
