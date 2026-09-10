import { afterEach, beforeEach, expect, test } from "bun:test";
import {
  adminApi,
  clearAdminSession,
  hasAdminSession,
  login,
  logoutAdmin,
} from "../apps/web/src/features/admin/admin-api";

const originalFetch = globalThis.fetch;
const memory = new Map<string, string>();
Object.defineProperty(globalThis, "sessionStorage", {
  configurable: true,
  value: {
    getItem: (key: string) => memory.get(key) ?? null,
    setItem: (key: string, value: string) => memory.set(key, value),
    removeItem: (key: string) => memory.delete(key),
  },
});
const token = (exp = Date.now() / 1000 + 3600, role = "ADMIN") =>
  `header.${btoa(JSON.stringify({ exp, role }))}.signature`;
const pair = (accessToken = token()) => ({ accessToken, refreshToken: "refresh-new" });
const json = (body: unknown, status = 200) => Response.json(body, { status });
const useFetch = (fn: (url: string, init?: RequestInit) => Promise<Response>) => {
  globalThis.fetch = fn as typeof fetch;
};
beforeEach(() => {
  clearAdminSession();
  memory.clear();
});
afterEach(() => {
  globalThis.fetch = originalFetch;
  clearAdminSession();
});

test("fresh login ignores stale storage and trims email, not password", async () => {
  memory.set("zennyt.admin.token", "stale");
  useFetch(async (url, init) => {
    expect(url).toBe("/api/v1/auth/login");
    expect(new Headers(init?.headers).has("Authorization")).toBe(false);
    expect(init?.cache).toBe("no-store");
    expect(JSON.parse(String(init?.body))).toEqual({
      email: "admin@test.local",
      password: " secret ",
    });
    return json(pair());
  });
  await login(" admin@test.local ", " secret ");
  expect(hasAdminSession()).toBe(true);
  expect(memory.get("zennyt.admin.refresh")).toBe("refresh-new");
});

test("401 is a credentials error but 500 and network failure are not", async () => {
  useFetch(async () => json({}, 401));
  await expect(login("a@b.c", "bad")).rejects.toThrow("Email ou mot de passe incorrect");
  useFetch(async () => json({}, 500));
  await expect(login("a@b.c", "good")).rejects.toThrow("backend indisponible (500)");
  useFetch(async () => {
    throw new TypeError("offline");
  });
  await expect(login("a@b.c", "good")).rejects.toThrow("Serveur inaccessible");
  expect(hasAdminSession()).toBe(false);
});

test("non-admin login never leaves an authenticated session", async () => {
  useFetch(async () => json(pair(token(undefined, "CANDIDATE"))));
  await expect(login("a@b.c", "good")).rejects.toThrow("rôle administrateur");
  expect(hasAdminSession()).toBe(false);
});

test("seven concurrent expired-token reads use a single refresh rotation", async () => {
  memory.set("zennyt.admin.token", token(1));
  memory.set("zennyt.admin.refresh", "refresh-old");
  let rotations = 0;
  useFetch(async (url, init) => {
    if (url.endsWith("/refresh")) {
      rotations++;
      return json(pair());
    }
    expect(new Headers(init?.headers).get("Authorization")).toContain("Bearer header.");
    return json({ ok: true });
  });
  await Promise.all(Array.from({ length: 7 }, () => adminApi("/overview")));
  expect(rotations).toBe(1);
});

test("parallel rejected access tokens refresh once and retry once", async () => {
  const stale = token(Date.now() / 1000 + 1800);
  memory.set("zennyt.admin.token", stale);
  memory.set("zennyt.admin.refresh", "refresh-old");
  let rotations = 0;
  useFetch(async (url, init) => {
    if (url.endsWith("/refresh")) {
      rotations++;
      return json(pair());
    }
    return new Headers(init?.headers).get("Authorization") === `Bearer ${stale}`
      ? json({}, 401)
      : json({ ok: true });
  });
  await Promise.all([adminApi("/overview"), adminApi("/assets")]);
  expect(rotations).toBe(1);
});

test("expired legacy access-only storage requests re-login", async () => {
  memory.set("zennyt.admin.token", "malformed-token");
  useFetch(async () => {
    throw new Error("must not fetch");
  });
  await expect(adminApi("/overview")).rejects.toThrow("Session expirée");
  expect(hasAdminSession()).toBe(false);
});

test("temporary refresh outage retains refresh token for retry", async () => {
  memory.set("zennyt.admin.refresh", "refresh-old");
  useFetch(async () => json({}, 503));
  await expect(adminApi("/overview")).rejects.toThrow("Renouvellement indisponible");
  expect(memory.get("zennyt.admin.refresh")).toBe("refresh-old");
});

test("invalid refresh clears the expired session", async () => {
  memory.set("zennyt.admin.refresh", "invalid");
  useFetch(async () => json({}, 401));
  await expect(adminApi("/overview")).rejects.toThrow("Session expirée");
  expect(hasAdminSession()).toBe(false);
});

test("logout during refresh cannot resurrect the session", async () => {
  memory.set("zennyt.admin.refresh", "refresh-old");
  let finish!: (response: Response) => void;
  useFetch(async (url) =>
    url.endsWith("/refresh")
      ? new Promise<Response>((resolve) => {
          finish = resolve;
        })
      : new Response(null, { status: 204 }),
  );
  const pending = adminApi("/overview");
  await logoutAdmin();
  finish(json(pair()));
  await expect(pending).rejects.toThrow("Session fermée");
  expect(hasAdminSession()).toBe(false);
});

test("logout revokes the refresh token and clears local storage immediately", async () => {
  memory.set("zennyt.admin.refresh", "refresh-old");
  useFetch(async (url, init) => {
    expect(url).toBe("/api/v1/auth/logout");
    expect(hasAdminSession()).toBe(false);
    expect(JSON.parse(String(init?.body))).toEqual({ refreshToken: "refresh-old" });
    return new Response(null, { status: 204 });
  });
  await logoutAdmin();
});
