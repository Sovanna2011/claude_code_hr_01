/*
 * Login tests for the HR Module demo server.
 *
 * Verifies the authentication contract that gates the whole app: every seeded
 * demo account (one "line" per role) signs in and receives the identity/role
 * the SAPUI5 login screen relies on, the issued token authorizes /api/auth/me,
 * and bad or missing credentials are refused.
 *
 * Run with:  node --test        (from the demo/ directory)
 */
"use strict";

const { test, before, after, describe } = require("node:test");
const assert = require("node:assert/strict");
const { makeApi, startServer } = require("../testkit");

const PORT = process.env.LOGIN_TEST_PORT || 8124;
const api = makeApi(`http://127.0.0.1:${PORT}`);
let server;

before(async () => { server = await startServer(PORT); });
after(() => { if (server) { server.kill(); } });

// The three demo accounts shown on the login screen — one per role.
const ACCOUNTS = [
    { username: "admin",   password: "admin123",   roleKey: "HR_ADMIN",   roleName: "HR Administrator",         displayName: "Alex Admin",       pernr: null },
    { username: "manager", password: "manager123", roleKey: "HR_MANAGER", roleName: "HR Manager",               displayName: "Andreas Schmidt",  pernr: 1000 },
    { username: "linda",   password: "linda123",   roleKey: "EMPLOYEE",   roleName: "Employee (Self-Service)",  displayName: "Linda Nguyen",     pernr: 1001 }
];

describe("login", () => {
    for (const acc of ACCOUNTS) {
        test(`${acc.username} signs in and receives the expected role and identity`, async () => {
            const { status, body } = await api("POST", "/api/auth/login", {
                body: { username: acc.username, password: acc.password }
            });
            assert.equal(status, 200);
            assert.ok(body.token, "a token is issued");
            assert.equal(body.user.username, acc.username);
            assert.equal(body.user.roleKey, acc.roleKey);
            assert.equal(body.user.roleName, acc.roleName);
            assert.equal(body.user.displayName, acc.displayName);
            assert.equal(body.user.pernr, acc.pernr);
        });
    }

    test("the issued token authorizes /api/auth/me with the same identity", async () => {
        const login = await api("POST", "/api/auth/login", { body: { username: "linda", password: "linda123" } });
        const me = await api("GET", "/api/auth/me", { token: login.body.token });
        assert.equal(me.status, 200);
        assert.deepEqual(me.body, login.body.user, "/me echoes the logged-in user");
    });

    test("a wrong password is rejected with 401 and no token", async () => {
        const { status, body } = await api("POST", "/api/auth/login", { body: { username: "admin", password: "wrong" } });
        assert.equal(status, 401);
        assert.ok(!body || !body.token, "no token on failed login");
    });

    test("an unknown user is rejected with 401", async () => {
        const { status } = await api("POST", "/api/auth/login", { body: { username: "ghost", password: "whatever" } });
        assert.equal(status, 401);
    });

    test("an empty password is rejected with 401", async () => {
        const { status } = await api("POST", "/api/auth/login", { body: { username: "admin", password: "" } });
        assert.equal(status, 401);
    });

    test("a protected endpoint without a token is rejected with 401", async () => {
        const { status } = await api("GET", "/api/auth/me");
        assert.equal(status, 401);
    });

    test("a garbage bearer token is rejected with 401", async () => {
        const { status } = await api("GET", "/api/auth/me", { token: "not-a-real-token" });
        assert.equal(status, 401);
    });
});
