/**
 * Types de vue de l'espace Utilisateurs : ce dont l'écran a besoin pour
 * s'afficher. Ce ne sont pas des types d'API — aucune forme de réponse
 * backend n'est supposée ici. Quand le contrat `/admin/**` sera publié, un
 * mapping remplira ces types depuis les DTO réels.
 */

/** Aligné sur l'énumération réelle backend `identity.domain.model.Role`. */
export type UserRole = "CANDIDATE" | "STUDENT" | "RECRUITER" | "ADMIN";

/** Dérivé des champs `active` / `deletedAt` du modèle `User`. */
export type UserStatus = "ACTIVE" | "DEACTIVATED" | "DELETED";

export interface UserRow {
  id: string;
  fullName: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  emailVerified: boolean;
  city: string | null;
  country: string | null;
  registeredAt: string;
  lastSeenAt: string | null;
  /** Pourcentage 0-100. */
  profileCompletion: number;
}

export interface UserSessionRow {
  id: string;
  device: string;
  location: string;
  lastSeenAt: string;
  current: boolean;
}

export interface UserActivityEntry {
  id: string;
  kind: "GAME" | "POST" | "APPLICATION" | "MESSAGE" | "AUTH";
  label: string;
  at: string;
}

export interface UserModerationEntry {
  id: string;
  at: string;
  action: string;
  reason: string;
}

export interface UserDetail extends UserRow {
  phoneNumber: string | null;
  address: string | null;
  onboardingStage: string;
  invitedBy: { id: string; name: string } | null;
  invitedCount: number;
  referralCode: string;
  sessions: UserSessionRow[];
  activity: UserActivityEntry[];
  moderation: UserModerationEntry[];
}

export interface UsersData {
  rows: UserRow[];
}

export const USER_ROLE_LABELS: Record<UserRole, string> = {
  CANDIDATE: "Candidat",
  STUDENT: "Étudiant",
  RECRUITER: "Recruteur",
  ADMIN: "Administrateur",
};

export const USER_STATUS_LABELS: Record<UserStatus, string> = {
  ACTIVE: "Actif",
  DEACTIVATED: "Désactivé",
  DELETED: "Supprimé",
};

export const USER_ROLE_OPTIONS = (Object.keys(USER_ROLE_LABELS) as UserRole[]).map((value) => ({
  value,
  label: USER_ROLE_LABELS[value],
}));

export const USER_STATUS_OPTIONS = (Object.keys(USER_STATUS_LABELS) as UserStatus[]).map(
  (value) => ({ value, label: USER_STATUS_LABELS[value] }),
);
