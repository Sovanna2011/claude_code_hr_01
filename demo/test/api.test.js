/*
 * API smoke tests for the HR Module demo server.
 *
 * These run against the self-contained demo (demo/server.js), which serves the
 * real SAPUI5 web app plus an in-memory stand-in of the REST API whose contract
 * matches the C# backend. They focus on the Leave Management workflow
 * (submit -> approve/reject, quota deduction, role scoping) and cover a few
 * core endpoints as a sanity check.
 *
 * Run with:  node --test        (from the demo/ directory)
 */
"use strict";

const { test, before, after, beforeEach, describe } = require("node:test");
const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const path = require("node:path");

const PORT = process.env.TEST_PORT || 8123;
const BASE = `http://127.0.0.1:${PORT}`;
let server;
let adminToken;   // used to reset the in-memory DB between tests

/** Minimal API helper. Returns { status, body } where body is parsed JSON (or null). */
async function api(method, pathname, { token, body } = {}) {
    const headers = { "Content-Type": "application/json" };
    if (token) { headers.Authorization = "Bearer " + token; }
    const res = await fetch(BASE + pathname, {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body)
    });
    const text = await res.text();
    let json = null;
    if (text) { try { json = JSON.parse(text); } catch (e) { json = text; } }
    return { status: res.status, body: json };
}

async function login(username, password) {
    const { status, body } = await api("POST", "/api/auth/login", { body: { username, password } });
    assert.equal(status, 200, `login(${username}) should succeed`);
    return body; // { token, user }
}

// ---- Server lifecycle ------------------------------------------------------
before(async () => {
    server = spawn("node", ["server.js"], {
        cwd: path.join(__dirname, ".."),
        env: { ...process.env, PORT: String(PORT) },
        stdio: ["ignore", "ignore", "inherit"]
    });
    // Wait until the server answers its health check.
    const deadline = Date.now() + 10000;
    for (;;) {
        try {
            const res = await fetch(BASE + "/health");
            if (res.ok) { break; }
        } catch (e) { /* not up yet */ }
        if (Date.now() > deadline) { throw new Error("demo server did not start in time"); }
        await new Promise(r => setTimeout(r, 150));
    }
    adminToken = (await login("admin", "admin123")).token;
});

after(() => { if (server) { server.kill(); } });

// Reset the in-memory database before each test for deterministic state.
// Only login is anonymous, so the reset call needs a bearer token.
beforeEach(async () => {
    const res = await api("POST", "/api/reset", { token: adminToken });
    assert.equal(res.status, 200);
});

// ---- Authentication --------------------------------------------------------
describe("authentication", () => {
    test("valid credentials return a token and user info", async () => {
        const { token, user } = await login("manager", "manager123");
        assert.ok(token, "a token is issued");
        assert.equal(user.roleKey, "HR_MANAGER");
        assert.equal(user.pernr, 1000);
    });

    test("invalid credentials are rejected with 401", async () => {
        const { status } = await api("POST", "/api/auth/login", { body: { username: "admin", password: "wrong" } });
        assert.equal(status, 401);
    });
});

// ---- Leave Management ------------------------------------------------------
describe("leave management", () => {
    test("employees see only their own requests; managers see all", async () => {
        const linda = await login("linda", "linda123");
        const manager = await login("manager", "manager123");

        const own = await api("GET", "/api/leave-requests", { token: linda.token });
        assert.equal(own.status, 200);
        assert.ok(own.body.every(r => r.pernr === 1001), "employee sees only their own PERNR");

        const all = await api("GET", "/api/leave-requests", { token: manager.token });
        assert.equal(all.status, 200);
        assert.ok(all.body.length >= own.body.length, "manager sees at least as many requests");
    });

    test("an employee submits a leave request (DTO shape, Pending)", async () => {
        const linda = await login("linda", "linda123");
        const { status, body } = await api("POST", "/api/leave-requests", {
            token: linda.token,
            body: { leaveType: "0100", begda: "2026-09-01", endda: "2026-09-03", note: "Trip" }
        });
        assert.equal(status, 201);
        assert.equal(body.status, "Pending");
        assert.equal(body.pernr, 1001);
        assert.equal(body.leaveTypeKey, "0100");
        assert.equal(body.leaveType, "Annual leave");   // resolved text
        assert.equal(body.days, 3);                      // calculated from dates
        assert.ok(body.requestId > 0);
    });

    test("approval posts the absence and deducts the matching quota", async () => {
        const linda = await login("linda", "linda123");
        const manager = await login("manager", "manager123");

        const before = await api("GET", "/api/employees/1001/leave-balances", { token: linda.token });
        const q0 = before.body.find(q => q.quotaType === "0100");

        const created = await api("POST", "/api/leave-requests", {
            token: linda.token,
            body: { leaveType: "0100", begda: "2026-10-05", endda: "2026-10-09" } // 5 days
        });
        assert.equal(created.status, 201);

        const decide = await api("POST", `/api/leave-requests/${created.body.requestId}/decide`, {
            token: manager.token, body: { approve: true }
        });
        assert.equal(decide.status, 204);

        const after = await api("GET", "/api/employees/1001/leave-balances", { token: linda.token });
        const q1 = after.body.find(q => q.quotaType === "0100");
        assert.equal(q1.deducted, q0.deducted + 5, "quota deducted by the approved days");
        assert.equal(q1.remaining, q0.remaining - 5);

        const list = await api("GET", "/api/leave-requests", { token: manager.token });
        const decided = list.body.find(r => r.requestId === created.body.requestId);
        assert.equal(decided.status, "Approved");
        assert.ok(decided.decidedBy, "decided-by is stamped");
        assert.ok(decided.decidedOn, "decided-on is stamped");
    });

    test("rejection sets status Rejected and does not touch the quota", async () => {
        const linda = await login("linda", "linda123");
        const manager = await login("manager", "manager123");

        const before = await api("GET", "/api/employees/1001/leave-balances", { token: linda.token });
        const q0 = before.body.find(q => q.quotaType === "0100");

        const created = await api("POST", "/api/leave-requests", {
            token: linda.token, body: { leaveType: "0100", begda: "2026-11-02", endda: "2026-11-02" }
        });
        const decide = await api("POST", `/api/leave-requests/${created.body.requestId}/decide`, {
            token: manager.token, body: { approve: false }
        });
        assert.equal(decide.status, 204);

        const after = await api("GET", "/api/employees/1001/leave-balances", { token: linda.token });
        const q1 = after.body.find(q => q.quotaType === "0100");
        assert.equal(q1.deducted, q0.deducted, "quota is unchanged on rejection");
    });

    test("approval is rejected when the remaining quota is insufficient", async () => {
        const linda = await login("linda", "linda123");
        const manager = await login("manager", "manager123");

        const created = await api("POST", "/api/leave-requests", {
            token: linda.token,
            body: { leaveType: "0100", begda: "2026-12-01", endda: "2026-12-05", days: 999 }
        });
        assert.equal(created.status, 201);

        const decide = await api("POST", `/api/leave-requests/${created.body.requestId}/decide`, {
            token: manager.token, body: { approve: true }
        });
        assert.equal(decide.status, 400, "insufficient quota blocks approval");
        assert.match(decide.body.message, /quota/i);

        // The request stays Pending after a blocked approval.
        const list = await api("GET", "/api/leave-requests", { token: manager.token });
        const still = list.body.find(r => r.requestId === created.body.requestId);
        assert.equal(still.status, "Pending");
    });

    test("a request can be decided only once", async () => {
        const manager = await login("manager", "manager123");
        // Seed request 1 is Pending; approve it, then try again.
        const first = await api("POST", "/api/leave-requests/1/decide", { token: manager.token, body: { approve: true } });
        assert.equal(first.status, 204);
        const second = await api("POST", "/api/leave-requests/1/decide", { token: manager.token, body: { approve: false } });
        assert.equal(second.status, 400, "already-decided request cannot be changed");
    });

    test("an employee cannot approve or reject requests", async () => {
        const linda = await login("linda", "linda123");
        const { status } = await api("POST", "/api/leave-requests/1/decide", { token: linda.token, body: { approve: true } });
        assert.equal(status, 403);
    });
});

// ---- Core sanity checks ----------------------------------------------------
describe("core endpoints", () => {
    test("the employee list requires an HR/manager role", async () => {
        const linda = await login("linda", "linda123");
        const manager = await login("manager", "manager123");
        assert.equal((await api("GET", "/api/employees", { token: linda.token })).status, 403);
        assert.equal((await api("GET", "/api/employees", { token: manager.token })).status, 200);
    });

    test("leave-type value help returns key/text pairs", async () => {
        const manager = await login("manager", "manager123");
        const { status, body } = await api("GET", "/api/valuehelp/absence-types", { token: manager.token });
        assert.equal(status, 200);
        assert.ok(body.some(v => v.key === "0100" && v.text === "Annual leave"));
    });

    test("the org structure resolves the executive board hierarchy", async () => {
        const manager = await login("manager", "manager123");
        const { status, body } = await api("GET", "/api/orgunits/50000001/structure", { token: manager.token });
        assert.equal(status, 200);
        assert.ok(Array.isArray(body.children) && body.children.length > 0, "root has child org units");
    });
});
