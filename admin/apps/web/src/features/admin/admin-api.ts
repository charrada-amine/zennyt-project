import type {
  AdminData,
  AuditEntry,
  Bank,
  Configuration,
  ConfigurationSchema,
  ManagedAsset,
  Overview,
  Question,
} from "./admin-types";

export class AdminApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

const TOKEN = "zennyt.admin.token";
const REFRESH = "zennyt.admin.refresh";
let sessionGeneration = 0;
let refreshing: Promise<string> | null = null;

export function hasAdminSession() {
  return Boolean(sessionStorage.getItem(TOKEN) || sessionStorage.getItem(REFRESH));
}

export function clearAdminSession() {
  sessionGeneration++;
  refreshing = null;
  for (const key of [TOKEN, REFRESH, "zennyt.admin.auth"]) sessionStorage.removeItem(key);
}

async function request(url: string, init?: RequestInit) {
  try {
    return await fetch(url, { ...init, cache: "no-store", credentials: "omit" });
  } catch {
    throw new AdminApiError(
      "Serveur inaccessible. Vérifiez que Docker et le backend sont démarrés.",
      0,
    );
  }
}

function claims(token: string): { role?: string; exp?: number } {
  try {
    const part = token.split(".")[1]!.replaceAll("-", "+").replaceAll("_", "/");
    const value: unknown = JSON.parse(atob(part.padEnd(Math.ceil(part.length / 4) * 4, "=")));
    return value && typeof value === "object" ? (value as { role?: string; exp?: number }) : {};
  } catch {
    return {};
  }
}

function storeTokens(body: { accessToken: string; refreshToken: string } | null) {
  if (!body || typeof body.accessToken !== "string" || typeof body.refreshToken !== "string")
    throw new AdminApiError("Réponse d'authentification invalide", 502);
  if (claims(body.accessToken).role !== "ADMIN")
    throw new AdminApiError("Ce compte ne possède pas le rôle administrateur", 403);
  sessionStorage.setItem(TOKEN, body.accessToken);
  sessionStorage.setItem(REFRESH, body.refreshToken);
  sessionStorage.setItem("zennyt.admin.auth", "true");
  return body.accessToken;
}

async function refreshAccessToken(): Promise<string> {
  if (refreshing) return refreshing;
  const generation = sessionGeneration;
  const refreshToken = sessionStorage.getItem(REFRESH);
  if (!refreshToken) {
    clearAdminSession();
    throw new AdminApiError("Session expirée. Reconnectez-vous.", 401);
  }
  const pending = (async () => {
    const response = await request("/api/v1/auth/refresh", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    if (generation !== sessionGeneration) throw new AdminApiError("Session fermée", 401);
    if (!response.ok) {
      if (response.status === 401 || response.status === 403) {
        clearAdminSession();
        throw new AdminApiError("Session expirée. Reconnectez-vous.", 401);
      }
      throw new AdminApiError(
        `Renouvellement indisponible (${response.status}). Réessayez.`,
        response.status,
      );
    }
    const body = await response.json();
    if (generation !== sessionGeneration) throw new AdminApiError("Session fermée", 401);
    return storeTokens(body);
  })();
  refreshing = pending;
  try {
    return await pending;
  } finally {
    if (refreshing === pending) refreshing = null;
  }
}

async function authorizedRequest(url: string, init?: RequestInit) {
  const generation = sessionGeneration;
  let token = sessionStorage.getItem(TOKEN);
  if (!token || (claims(token).exp ?? 0) * 1000 <= Date.now() + 30_000)
    token = await refreshAccessToken();
  if (generation !== sessionGeneration) throw new AdminApiError("Session fermée", 401);
  const headers = new Headers(init?.headers);
  headers.set("Authorization", `Bearer ${token}`);
  if (init?.body && !(init.body instanceof FormData))
    headers.set("Content-Type", "application/json");
  let response = await request(url, { ...init, headers });
  if (generation !== sessionGeneration) throw new AdminApiError("Session fermée", 401);
  if (response.status === 401) {
    // Parallel requests may have already rotated this token. Never rotate twice.
    const current = sessionStorage.getItem(TOKEN);
    token = current && current !== token ? current : await refreshAccessToken();
    headers.set("Authorization", `Bearer ${token}`);
    response = await request(url, { ...init, headers });
    if (generation !== sessionGeneration) throw new AdminApiError("Session fermée", 401);
    if (response.status === 401) clearAdminSession();
  }
  return response;
}

export async function adminApi<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await authorizedRequest(`/api/v1/games/admin${path}`, init);
  if (!response.ok) {
    const error = (await response.json().catch(() => null)) as { message?: string } | null;
    throw new AdminApiError(
      error?.message ?? `La requête a échoué (${response.status})`,
      response.status,
    );
  }
  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

export async function authenticatedAssetUrl(url: string): Promise<string> {
  if (!url.startsWith("/api/v1/games/admin/assets/")) return url;
  const response = await authorizedRequest(url);
  if (!response.ok) throw new AdminApiError("Aperçu de l'asset indisponible", response.status);
  return URL.createObjectURL(await response.blob());
}

export async function loadAdminData(): Promise<AdminData> {
  const [overview, questions, banks, configurations, configurationSchemas, assets, audit] =
    await Promise.all([
      adminApi<Overview>("/overview"),
      adminApi<Question[]>("/questions"),
      adminApi<Bank[]>("/banks"),
      adminApi<Configuration[]>("/configurations"),
      adminApi<ConfigurationSchema[]>("/configuration-schemas"),
      adminApi<ManagedAsset[]>("/assets"),
      adminApi<AuditEntry[]>("/releases"),
    ]);
  return { overview, questions, banks, configurations, configurationSchemas, assets, audit };
}

export async function login(email: string, password: string) {
  clearAdminSession();
  const generation = sessionGeneration;
  const response = await request("/api/v1/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: email.trim(), password }),
  });
  if (!response.ok) {
    const message =
      response.status === 401
        ? "Email ou mot de passe incorrect"
        : response.status === 403
          ? "Accès refusé. Vérifiez l'état du compte."
          : response.status === 429
            ? "Trop de tentatives. Patientez avant de réessayer."
            : `Connexion au backend indisponible (${response.status}). Ce n'est pas une erreur de mot de passe.`;
    throw new AdminApiError(message, response.status);
  }
  const body = await response.json();
  if (generation !== sessionGeneration) throw new AdminApiError("Session fermée", 401);
  storeTokens(body);
}

export async function logoutAdmin() {
  const refreshToken = sessionStorage.getItem(REFRESH);
  clearAdminSession();
  if (refreshToken) {
    const response = await request("/api/v1/auth/logout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    if (!response.ok)
      throw new AdminApiError(
        "Session locale fermée ; révocation serveur indisponible.",
        response.status,
      );
  }
}
