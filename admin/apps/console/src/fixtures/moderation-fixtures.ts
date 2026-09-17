/** ⚠️ PROVISOIRE — voir l'avertissement de demo-people.ts. */

import type {
  ContentKind,
  ModerationData,
  ReportDetail,
  ReportPriority,
  ReportReason,
  ReportRow,
  ReportStatus,
  ReporterEntry,
  SanctionRow,
} from "@/features/moderation/moderation-view";
import { DEMO_PEOPLE, daysAgo, hoursAgo, person, personRef } from "@/fixtures/demo-people";
import { demo } from "@/lib/data-source";

interface Seed {
  kind: ContentKind;
  excerpt: string;
  reason: ReportReason;
  status: ReportStatus;
  priority: ReportPriority;
  reportCount: number;
  hoursAgo: number;
  authorIndex: number;
}

const SEEDS: Seed[] = [
  {
    kind: "POST",
    excerpt: "Ce recruteur ne répond jamais, c'est une honte, allez voir ailleurs…",
    reason: "HARASSMENT",
    status: "NEW",
    priority: "HIGH",
    reportCount: 7,
    hoursAgo: 3,
    authorIndex: 5,
  },
  {
    kind: "COMMENT",
    excerpt: "Gagnez 5000 € par semaine depuis chez vous — lien en bio",
    reason: "SPAM",
    status: "NEW",
    priority: "MEDIUM",
    reportCount: 4,
    hoursAgo: 9,
    authorIndex: 17,
  },
  {
    kind: "PROFILE",
    excerpt: "Profil « Directeur RH » sans entreprise vérifiable, photo réutilisée",
    reason: "FAKE_PROFILE",
    status: "IN_REVIEW",
    priority: "HIGH",
    reportCount: 5,
    hoursAgo: 20,
    authorIndex: 20,
  },
  {
    kind: "MESSAGE",
    excerpt: "Messages insistants envoyés à plusieurs candidates après refus",
    reason: "HARASSMENT",
    status: "IN_REVIEW",
    priority: "HIGH",
    reportCount: 3,
    hoursAgo: 28,
    authorIndex: 13,
  },
  {
    kind: "POST",
    excerpt: "Publication contenant des propos discriminatoires sur l'origine",
    reason: "HATE_SPEECH",
    status: "NEW",
    priority: "HIGH",
    reportCount: 11,
    hoursAgo: 34,
    authorIndex: 9,
  },
  {
    kind: "COMMENT",
    excerpt: "Répétition du même lien d'affiliation sur douze publications",
    reason: "SPAM",
    status: "RESOLVED",
    priority: "LOW",
    reportCount: 2,
    hoursAgo: 52,
    authorIndex: 23,
  },
  {
    kind: "POST",
    excerpt: "Image inappropriée jointe à une offre de stage",
    reason: "SEXUAL_CONTENT",
    status: "RESOLVED",
    priority: "MEDIUM",
    reportCount: 6,
    hoursAgo: 74,
    authorIndex: 3,
  },
  {
    kind: "PROFILE",
    excerpt: "Usurpation présumée d'un cabinet de recrutement connu",
    reason: "FAKE_PROFILE",
    status: "REJECTED",
    priority: "LOW",
    reportCount: 1,
    hoursAgo: 96,
    authorIndex: 11,
  },
  {
    kind: "MESSAGE",
    excerpt: "Demande de paiement pour « garantir » une embauche",
    reason: "OTHER",
    status: "NEW",
    priority: "HIGH",
    reportCount: 8,
    hoursAgo: 41,
    authorIndex: 16,
  },
  {
    kind: "COMMENT",
    excerpt: "Attaques répétées contre un autre candidat en commentaire",
    reason: "HARASSMENT",
    status: "IN_REVIEW",
    priority: "MEDIUM",
    reportCount: 3,
    hoursAgo: 63,
    authorIndex: 18,
  },
  {
    kind: "POST",
    excerpt: "Offre d'emploi renvoyant vers un site de collecte de données",
    reason: "SPAM",
    status: "NEW",
    priority: "MEDIUM",
    reportCount: 5,
    hoursAgo: 15,
    authorIndex: 25,
  },
  {
    kind: "COMMENT",
    excerpt: "Commentaire moqueur sur le handicap d'un autre membre",
    reason: "HATE_SPEECH",
    status: "RESOLVED",
    priority: "HIGH",
    reportCount: 9,
    hoursAgo: 120,
    authorIndex: 8,
  },
];

export const REPORT_ROWS: ReportRow[] = SEEDS.map((seed, index) => ({
  id: `rep_${String(index + 1).padStart(3, "0")}`,
  contentKind: seed.kind,
  excerpt: seed.excerpt,
  author: personRef(DEMO_PEOPLE[seed.authorIndex]!.id),
  reason: seed.reason,
  reportCount: seed.reportCount,
  status: seed.status,
  priority: seed.priority,
  reportedAt: hoursAgo(seed.hoursAgo),
}));

const REPORTER_NOTES = [
  "Comportement répété malgré un premier signalement.",
  "Le contenu est resté visible plus de 24 h.",
  "Plusieurs membres du groupe sont concernés.",
  "Capture d'écran envoyée au support.",
];

export const SANCTION_ROWS: SanctionRow[] = [
  {
    id: "san_001",
    user: personRef(DEMO_PEOPLE[5]!.id),
    kind: "SUSPENSION",
    reason: "Harcèlement caractérisé",
    issuedAt: daysAgo(4),
    until: daysAgo(-10),
  },
  {
    id: "san_002",
    user: personRef(DEMO_PEOPLE[20]!.id),
    kind: "SUSPENSION",
    reason: "Faux profil recruteur",
    issuedAt: daysAgo(9),
    until: daysAgo(-21),
  },
  {
    id: "san_003",
    user: personRef(DEMO_PEOPLE[17]!.id),
    kind: "WARNING",
    reason: "Spam en commentaire",
    issuedAt: daysAgo(12),
    until: null,
  },
  {
    id: "san_004",
    user: personRef(DEMO_PEOPLE[8]!.id),
    kind: "WARNING",
    reason: "Propos limites sur l'origine",
    issuedAt: daysAgo(18),
    until: null,
  },
];

/** PROVISOIRE — alimente la pastille « Modération » de la barre latérale. */
export const OPEN_REPORTS = REPORT_ROWS.filter((row) => row.status === "NEW").length;

export function loadModeration(): Promise<ModerationData> {
  return demo({
    rows: REPORT_ROWS,
    sanctions: SANCTION_ROWS,
    stats: {
      open: OPEN_REPORTS,
      inReview: REPORT_ROWS.filter((row) => row.status === "IN_REVIEW").length,
      resolved7d: REPORT_ROWS.filter((row) => row.status === "RESOLVED").length,
      activeSanctions: SANCTION_ROWS.filter((row) => row.until !== null).length,
      medianResolutionHours: 14,
    },
  });
}

export function loadReportDetail(reportId: string): Promise<ReportDetail> {
  const row = REPORT_ROWS.find((entry) => entry.id === reportId);
  if (!row) return Promise.reject(new Error(`Signalement ${reportId} introuvable`));

  const index = REPORT_ROWS.indexOf(row);
  const reporters: ReporterEntry[] = Array.from(
    { length: Math.min(row.reportCount, 4) },
    (_, position) => {
      const source = DEMO_PEOPLE[(index * 5 + position + 2) % DEMO_PEOPLE.length]!;
      return {
        id: `rpt_${row.id}_${position}`,
        name: source.fullName,
        reason: row.reason,
        note: REPORTER_NOTES[position % REPORTER_NOTES.length]!,
        at: hoursAgo(2 + position * 6),
      };
    },
  );

  const author = person(row.author.id);
  return demo({
    ...row,
    content: `${row.excerpt} — contenu complet reconstitué pour la démonstration, tel qu'il apparaîtrait dans le fil d'origine avec sa mise en forme et ses éventuelles pièces jointes.`,
    context:
      row.contentKind === "MESSAGE"
        ? "Conversation privée entre deux membres"
        : row.contentKind === "PROFILE"
          ? "Profil public"
          : "Fil communauté — visibilité publique",
    reporters,
    authorHistory: {
      previousReports: index % 4,
      previousSanctions: index % 3 === 0 ? 1 : 0,
      memberSince: daysAgo(author.registeredDaysAgo),
    },
  });
}
