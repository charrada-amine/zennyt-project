import type {
  AdminData,
  AuditEntry,
  Bank,
  Configuration,
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

export async function adminApi<T>(path: string, init?: RequestInit): Promise<T> {
  const token = sessionStorage.getItem("zennyt.admin.token");
  const headers = new Headers(init?.headers);
  if (token) headers.set("Authorization", `Bearer ${token}`);
  if (init?.body && !(init.body instanceof FormData))
    headers.set("Content-Type", "application/json");
  const response = await fetch(`/api/v1/games/admin${path}`, { ...init, headers });
  if (response.status === 401) {
    sessionStorage.removeItem("zennyt.admin.auth");
    sessionStorage.removeItem("zennyt.admin.token");
  }
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
  const token = sessionStorage.getItem("zennyt.admin.token");
  const response = await fetch(url, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
  if (!response.ok) throw new AdminApiError("Aperçu de l'asset indisponible", response.status);
  return URL.createObjectURL(await response.blob());
}

export async function loadAdminData(): Promise<AdminData> {
  const [overview, questions, banks, configurations, assets, audit] = await Promise.all([
    adminApi<Overview>("/overview"),
    adminApi<Question[]>("/questions"),
    adminApi<Bank[]>("/banks"),
    adminApi<Configuration[]>("/configurations"),
    adminApi<ManagedAsset[]>("/assets"),
    adminApi<AuditEntry[]>("/releases"),
  ]);
  return { overview, questions, banks, configurations, assets, audit };
}

export async function login(email: string, password: string) {
  const response = await fetch("/api/v1/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  if (!response.ok) throw new AdminApiError("Identifiants invalides", response.status);
  const body = (await response.json()) as { accessToken: string };
  const encodedPayload = body.accessToken.split(".")[1];
  if (!encodedPayload) throw new Error("Jeton d'authentification invalide");
  const normalized = encodedPayload.replaceAll("-", "+").replaceAll("_", "/");
  const payload = JSON.parse(
    atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=")),
  ) as {
    role?: string;
  };
  if (payload.role !== "ADMIN") throw new Error("Ce compte ne possède pas le rôle administrateur");
  sessionStorage.setItem("zennyt.admin.token", body.accessToken);
  sessionStorage.setItem("zennyt.admin.auth", "true");
}
