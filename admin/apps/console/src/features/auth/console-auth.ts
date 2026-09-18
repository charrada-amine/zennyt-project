/**
 * Authentification de la console plateforme.
 *
 * MODE DÉMONSTRATION : aucun appel réseau, n'importe quel identifiant non vide
 * ouvre la session. C'est délibéré — la console doit être démontrable sans
 * Docker ni Spring tant qu'elle sert des fixtures.
 *
 * Le remplacement est déjà écrit et éprouvé côté Game Studio
 * (apps/web/src/features/admin/admin-api.ts) : POST /api/v1/auth/login,
 * vérification du claim JWT `role=ADMIN`, refresh mutualisé, tokens en
 * sessionStorage. Seules les trois fonctions ci-dessous changent.
 */

const SESSION_KEY = "zennyt.console.auth";

/** À n'appeler que côté navigateur (effet, gestionnaire d'événement). */
export function hasConsoleSession() {
  try {
    return sessionStorage.getItem(SESSION_KEY) === "true";
  } catch {
    return false;
  }
}

export async function signIn(email: string, password: string): Promise<void> {
  if (!email.trim() || !password) {
    throw new Error("Renseignez un e-mail et un mot de passe.");
  }
  // Latence simulée : le bouton passe réellement par son état « en cours ».
  await new Promise((resolve) => setTimeout(resolve, 320));
  sessionStorage.setItem(SESSION_KEY, "true");
  sessionStorage.setItem("zennyt.console.email", email.trim());
}

export function signOut() {
  sessionStorage.removeItem(SESSION_KEY);
  sessionStorage.removeItem("zennyt.console.email");
}

export function currentEmail() {
  try {
    return sessionStorage.getItem("zennyt.console.email") ?? "";
  } catch {
    return "";
  }
}
