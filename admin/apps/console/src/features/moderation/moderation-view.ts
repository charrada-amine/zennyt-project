/**
 * Types de vue de l'espace Modération. Voir l'avertissement de users-view.ts.
 *
 * Les types de contenu reprennent ce que le contexte `engagement` manipule
 * réellement (Post, Comment, Message, Profile). Les motifs de signalement et
 * les sanctions, eux, n'existent nulle part côté backend : ce sont des
 * hypothèses d'écran, à confronter au contrat quand il sortira.
 */

export type ContentKind = "POST" | "COMMENT" | "MESSAGE" | "PROFILE";
export type ReportStatus = "NEW" | "IN_REVIEW" | "RESOLVED" | "REJECTED";
export type ReportPriority = "HIGH" | "MEDIUM" | "LOW";
export type ReportReason =
  | "HARASSMENT"
  | "SPAM"
  | "HATE_SPEECH"
  | "SEXUAL_CONTENT"
  | "FAKE_PROFILE"
  | "OTHER";

export interface ReportRow {
  id: string;
  contentKind: ContentKind;
  excerpt: string;
  author: { id: string; name: string; email: string };
  reason: ReportReason;
  reportCount: number;
  status: ReportStatus;
  priority: ReportPriority;
  reportedAt: string;
}

export interface ReporterEntry {
  id: string;
  name: string;
  reason: ReportReason;
  note: string;
  at: string;
}

export interface SanctionRow {
  id: string;
  user: { id: string; name: string; email: string };
  kind: "WARNING" | "SUSPENSION";
  reason: string;
  issuedAt: string;
  until: string | null;
}

export interface ReportDetail extends ReportRow {
  content: string;
  context: string;
  reporters: ReporterEntry[];
  authorHistory: {
    previousReports: number;
    previousSanctions: number;
    memberSince: string;
  };
}

export interface ModerationStats {
  open: number;
  inReview: number;
  resolved7d: number;
  activeSanctions: number;
  medianResolutionHours: number;
}

export interface ModerationData {
  rows: ReportRow[];
  sanctions: SanctionRow[];
  stats: ModerationStats;
}

export const CONTENT_KIND_LABELS: Record<ContentKind, string> = {
  POST: "Publication",
  COMMENT: "Commentaire",
  MESSAGE: "Message",
  PROFILE: "Profil",
};

export const REPORT_STATUS_LABELS: Record<ReportStatus, string> = {
  NEW: "Nouveau",
  IN_REVIEW: "En cours",
  RESOLVED: "Résolu",
  REJECTED: "Rejeté",
};

export const REPORT_REASON_LABELS: Record<ReportReason, string> = {
  HARASSMENT: "Harcèlement",
  SPAM: "Spam",
  HATE_SPEECH: "Propos haineux",
  SEXUAL_CONTENT: "Contenu sexuel",
  FAKE_PROFILE: "Faux profil",
  OTHER: "Autre",
};

export const REPORT_PRIORITY_LABELS: Record<ReportPriority, string> = {
  HIGH: "Haute",
  MEDIUM: "Moyenne",
  LOW: "Basse",
};

export const CONTENT_KIND_OPTIONS = (Object.keys(CONTENT_KIND_LABELS) as ContentKind[]).map(
  (value) => ({ value, label: CONTENT_KIND_LABELS[value] }),
);

export const REPORT_STATUS_OPTIONS = (Object.keys(REPORT_STATUS_LABELS) as ReportStatus[]).map(
  (value) => ({ value, label: REPORT_STATUS_LABELS[value] }),
);

export const REPORT_REASON_OPTIONS = (Object.keys(REPORT_REASON_LABELS) as ReportReason[]).map(
  (value) => ({ value, label: REPORT_REASON_LABELS[value] }),
);
