/*
 * Shared test helpers: spawn the demo server on a given port and build a small
 * fetch-based API client bound to it.
 */
"use strict";

const { spawn } = require("node:child_process");

/** Builds an API client bound to `base`. Returns { status, body } (body = parsed JSON or null). */
function makeApi(base) {
    return async function api(method, pathname, { token, body } = {}) {
        const headers = { "Content-Type": "application/json" };
        if (token) { headers.Authorization = "Bearer " + token; }
        const res = await fetch(base + pathname, {
            method,
            headers,
            body: body === undefined ? undefined : JSON.stringify(body)
        });
        const text = await res.text();
        let json = null;
        if (text) { try { json = JSON.parse(text); } catch (e) { json = text; } }
        return { status: res.status, body: json };
    };
}

/** Spawns demo/server.js on `port` and resolves once it answers /health. */
async function startServer(port) {
    const server = spawn("node", ["server.js"], {
        cwd: __dirname,
        env: { ...process.env, PORT: String(port) },
        stdio: ["ignore", "ignore", "inherit"]
    });
    const base = `http://127.0.0.1:${port}`;
    const deadline = Date.now() + 10000;
    for (;;) {
        try {
            const res = await fetch(base + "/health");
            if (res.ok) { return server; }
        } catch (e) { /* not up yet */ }
        if (Date.now() > deadline) { server.kill(); throw new Error("demo server did not start in time"); }
        await new Promise(r => setTimeout(r, 150));
    }
}

module.exports = { makeApi, startServer };
