/** ⚠️ PROVISOIRE — voir l'avertissement de demo-people.ts. */

import type {
  FilleulEntry,
  FilleulStatus,
  ReferralsData,
  SponsorRow,
  SponsorStatus,
} from "@/features/referrals/referrals-view";
import { DEMO_PEOPLE, daysAgo } from "@/fixtures/demo-people";
import { demo } from "@/lib/data-source";

const FILLEUL_STATUSES: FilleulStatus[] = [
  "QUALIFIED",
  "REGISTERED",
  "QUALIFIED",
  "INVITED",
  "REGISTERED",
  "QUALIFIED",
];

/** PROVISOIRE — bonus unitaire d'affichage, le vrai barème est serveur. */
const BONUS_PER_QUALIFIED = 25;

const SPONSORS = DEMO_PEOPLE.filter((entry) => entry.status === "ACTIVE").slice(0, 12);

export const SPONSOR_ROWS: SponsorRow[] = SPONSORS.map((entry, index) => {
  const invited = 12 - index + (index % 3);
  const filleuls: FilleulEntry[] = Array.from({ length: Math.min(invited, 6) }, (_, child) => {
    const source = DEMO_PEOPLE[(index * 3 + child + 5) % DEMO_PEOPLE.length]!;
    const status = FILLEUL_STATUSES[(index + child) % FILLEUL_STATUSES.length]!;
    return {
      id: `fil_${entry.id}_${child}`,
      name: source.fullName,
      email: source.email,
      status,
      joinedAt: status === "INVITED" ? null : daysAgo(3 + child * 4 + index),
    };
  });
  const qualified = filleuls.filter((child) => child.status === "QUALIFIED").length;
  const registered = filleuls.filter((child) => child.status !== "INVITED").length;

  return {
    id: `spo_${String(index + 1).padStart(3, "0")}`,
    userId: entry.id,
    name: entry.fullName,
    email: entry.email,
    code: `ZEN-${entry.id.slice(-3)}${entry.fullName.slice(0, 2).toUpperCase()}`,
    invited,
    registered,
    qualified,
    bonusEarned: qualified * BONUS_PER_QUALIFIED,
    bonusPending: (registered - qualified) * BONUS_PER_QUALIFIED,
    status: (index === 4 || index === 9 ? "PAUSED" : "ACTIVE") as SponsorStatus,
    filleuls,
  };
}).sort((left, right) => right.qualified - left.qualified || right.invited - left.invited);

export function loadReferrals(): Promise<ReferralsData> {
  const totalInvited = SPONSOR_ROWS.reduce((sum, row) => sum + row.invited, 0);
  const totalQualified = SPONSOR_ROWS.reduce((sum, row) => sum + row.qualified, 0);

  return demo({
    rows: SPONSOR_ROWS,
    stats: {
      activeSponsors: SPONSOR_ROWS.filter((row) => row.status === "ACTIVE").length,
      qualifiedFilleuls: totalQualified,
      bonusPaid: SPONSOR_ROWS.reduce((sum, row) => sum + row.bonusEarned, 0),
      bonusPending: SPONSOR_ROWS.reduce((sum, row) => sum + row.bonusPending, 0),
      conversionRate: (totalQualified / Math.max(totalInvited, 1)) * 100,
    },
    // Affiché en lecture seule : le barème du programme est une règle serveur.
    rules: [
      {
        label: "Bonus par filleul qualifié",
        value: `${BONUS_PER_QUALIFIED} €`,
        detail: "Versé une fois le filleul qualifié.",
      },
      {
        label: "Condition de qualification",
        value: "Profil complet + 1 session de jeu",
        detail: "Vérifiée côté serveur, non modifiable ici.",
      },
      {
        label: "Plafond mensuel par parrain",
        value: "500 €",
        detail: "Au-delà, les bonus restent en attente.",
      },
      {
        label: "Validité du lien de parrainage",
        value: "30 jours",
        detail: "Passé ce délai, l'invitation expire.",
      },
    ],
  });
}
