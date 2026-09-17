/** Types de vue de l'espace Parrainage. Voir l'avertissement de users-view.ts. */

export type FilleulStatus = "INVITED" | "REGISTERED" | "QUALIFIED";
export type SponsorStatus = "ACTIVE" | "PAUSED";

export interface FilleulEntry {
  id: string;
  name: string;
  email: string;
  status: FilleulStatus;
  joinedAt: string | null;
}

export interface SponsorRow {
  id: string;
  userId: string;
  name: string;
  email: string;
  code: string;
  invited: number;
  registered: number;
  qualified: number;
  bonusEarned: number;
  bonusPending: number;
  status: SponsorStatus;
  filleuls: FilleulEntry[];
}

export interface ProgramRule {
  label: string;
  value: string;
  detail: string;
}

export interface ReferralsStats {
  activeSponsors: number;
  qualifiedFilleuls: number;
  bonusPaid: number;
  bonusPending: number;
  conversionRate: number;
}

export interface ReferralsData {
  rows: SponsorRow[];
  stats: ReferralsStats;
  /**
   * Règles affichées en lecture seule : le barème du programme est une règle
   * métier serveur. La console le montre, elle ne le modifie pas — même
   * discipline que le bandeau « Barèmes protégés » de la console Game Studio.
   */
  rules: ProgramRule[];
}

export const FILLEUL_STATUS_LABELS: Record<FilleulStatus, string> = {
  INVITED: "Invité",
  REGISTERED: "Inscrit",
  QUALIFIED: "Qualifié",
};

export const SPONSOR_STATUS_LABELS: Record<SponsorStatus, string> = {
  ACTIVE: "Actif",
  PAUSED: "En pause",
};

export const SPONSOR_STATUS_OPTIONS = (Object.keys(SPONSOR_STATUS_LABELS) as SponsorStatus[]).map(
  (value) => ({ value, label: SPONSOR_STATUS_LABELS[value] }),
);
