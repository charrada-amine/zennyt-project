/** ⚠️ PROVISOIRE — voir l'avertissement de demo-people.ts. */

import type {
  InviteChannel,
  InviteRow,
  InviteStatus,
  InvitesData,
} from "@/features/invites/invites-view";
import { DEMO_PEOPLE, daysAgo, daysAhead, personRef } from "@/fixtures/demo-people";
import { demo } from "@/lib/data-source";

const STATUSES: InviteStatus[] = [
  "PENDING",
  "ACCEPTED",
  "ACCEPTED",
  "EXPIRED",
  "PENDING",
  "REVOKED",
];
const CHANNELS: InviteChannel[] = ["EMAIL", "LINK", "EMAIL", "SMS", "LINK", "EMAIL"];
const RECIPIENTS = [
  "marine.dupont@example.com",
  "s.bouzid@example.com",
  "gregory.faure@example.com",
  "l.moreno@example.com",
  "chantal.nkem@example.com",
  "tarek.aziz@example.com",
  "helene.vasseur@example.com",
  "d.oliveira@example.com",
  "farida.mansour@example.com",
  "vincent.roy@example.com",
  "aicha.diop@example.com",
  "paul.brunet@example.com",
  "noemie.charpentier@example.com",
  "r.kaczmarek@example.com",
  "issa.konate@example.com",
  "valerie.pichon@example.com",
  "youssef.amrani@example.com",
  "beatrice.lang@example.com",
  "samir.hakimi@example.com",
  "juliette.morel@example.com",
  "kevin.barre@example.com",
  "nour.eddine@example.com",
];

// Seuls les comptes actifs parrainent : un compte supprimé n'envoie pas d'invitation.
const INVITERS = DEMO_PEOPLE.filter((entry) => entry.status === "ACTIVE").slice(0, 10);

export const INVITE_ROWS: InviteRow[] = RECIPIENTS.map((recipient, index) => {
  const status = STATUSES[index % STATUSES.length]!;
  const createdDaysAgo = 1 + index * 2;
  return {
    id: `inv_${String(index + 1).padStart(3, "0")}`,
    code: `ZEN-${(index + 1) * 7919}`.slice(0, 12).toUpperCase(),
    recipient,
    channel: CHANNELS[index % CHANNELS.length]!,
    status,
    invitedBy: personRef(INVITERS[index % INVITERS.length]!.id),
    createdAt: daysAgo(createdDaysAgo),
    expiresAt: status === "EXPIRED" ? daysAgo(createdDaysAgo - 14) : daysAhead(30 - index),
    acceptedAt: status === "ACCEPTED" ? daysAgo(Math.max(createdDaysAgo - 2, 0)) : null,
  };
});

function count(status: InviteStatus) {
  return INVITE_ROWS.filter((row) => row.status === status).length;
}

export function loadInvites(): Promise<InvitesData> {
  const accepted = count("ACCEPTED");
  return demo({
    rows: INVITE_ROWS,
    stats: {
      sent: INVITE_ROWS.length,
      accepted,
      pending: count("PENDING"),
      expired: count("EXPIRED"),
      acceptanceRate: (accepted / INVITE_ROWS.length) * 100,
    },
  });
}
