/** Types de vue de l'espace Invitations. Voir l'avertissement de users-view.ts. */

export type InviteStatus = "PENDING" | "ACCEPTED" | "EXPIRED" | "REVOKED";
export type InviteChannel = "EMAIL" | "LINK" | "SMS";

export interface InviteRow {
  id: string;
  code: string;
  recipient: string;
  channel: InviteChannel;
  status: InviteStatus;
  invitedBy: { id: string; name: string; email: string };
  createdAt: string;
  expiresAt: string;
  acceptedAt: string | null;
}

export interface InvitesStats {
  sent: number;
  accepted: number;
  pending: number;
  expired: number;
  acceptanceRate: number;
}

export interface InvitesData {
  rows: InviteRow[];
  stats: InvitesStats;
}

export const INVITE_STATUS_LABELS: Record<InviteStatus, string> = {
  PENDING: "En attente",
  ACCEPTED: "Acceptée",
  EXPIRED: "Expirée",
  REVOKED: "Révoquée",
};

export const INVITE_CHANNEL_LABELS: Record<InviteChannel, string> = {
  EMAIL: "E-mail",
  LINK: "Lien",
  SMS: "SMS",
};

export const INVITE_STATUS_OPTIONS = (Object.keys(INVITE_STATUS_LABELS) as InviteStatus[]).map(
  (value) => ({ value, label: INVITE_STATUS_LABELS[value] }),
);

export const INVITE_CHANNEL_OPTIONS = (Object.keys(INVITE_CHANNEL_LABELS) as InviteChannel[]).map(
  (value) => ({ value, label: INVITE_CHANNEL_LABELS[value] }),
);
