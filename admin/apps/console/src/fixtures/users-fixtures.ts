/** ⚠️ PROVISOIRE — voir l'avertissement de demo-people.ts. */

import type {
  UserActivityEntry,
  UserDetail,
  UserModerationEntry,
  UserRow,
  UserSessionRow,
  UsersData,
} from "@/features/users/users-view";
import { DEMO_PEOPLE, daysAgo, hoursAgo, person } from "@/fixtures/demo-people";
import { demo } from "@/lib/data-source";

function toRow(entry: (typeof DEMO_PEOPLE)[number]): UserRow {
  return {
    id: entry.id,
    fullName: entry.fullName,
    email: entry.email,
    role: entry.role,
    status: entry.status,
    emailVerified: entry.emailVerified,
    city: entry.city,
    country: entry.country,
    registeredAt: daysAgo(entry.registeredDaysAgo),
    lastSeenAt: entry.lastSeenDaysAgo === null ? null : daysAgo(entry.lastSeenDaysAgo),
    profileCompletion: entry.profileCompletion,
  };
}

export const USER_ROWS: UserRow[] = DEMO_PEOPLE.map(toRow);

const ONBOARDING_STAGES = [
  "Terminé",
  "Compétences renseignées",
  "CV importé",
  "Compte créé",
] as const;

const SESSIONS: UserSessionRow[] = [
  {
    id: "ses_1",
    device: "iPhone 15 · iOS 18.4",
    location: "Lyon, France",
    lastSeenAt: hoursAgo(2),
    current: true,
  },
  {
    id: "ses_2",
    device: "Chrome 142 · macOS",
    location: "Lyon, France",
    lastSeenAt: daysAgo(3),
    current: false,
  },
  {
    id: "ses_3",
    device: "Pixel 9 · Android 16",
    location: "Paris, France",
    lastSeenAt: daysAgo(11),
    current: false,
  },
];

const ACTIVITY: UserActivityEntry[] = [
  {
    id: "act_1",
    kind: "GAME",
    label: "Session « Emotional Radar » terminée — score 78/100",
    at: hoursAgo(3),
  },
  {
    id: "act_2",
    kind: "APPLICATION",
    label: "Candidature envoyée — Développeur Full-Stack, Sopra",
    at: daysAgo(1),
  },
  { id: "act_3", kind: "POST", label: "Publication créée dans le fil communauté", at: daysAgo(2) },
  {
    id: "act_4",
    kind: "GAME",
    label: "Session « Memory Quest » terminée — score 64/100",
    at: daysAgo(4),
  },
  {
    id: "act_5",
    kind: "AUTH",
    label: "Connexion depuis un nouvel appareil (Pixel 9)",
    at: daysAgo(11),
  },
];

const MODERATION: UserModerationEntry[] = [
  {
    id: "mod_1",
    at: daysAgo(23),
    action: "Avertissement",
    reason: "Propos déplacés en commentaire",
  },
];

export function loadUsers(): Promise<UsersData> {
  return demo({ rows: USER_ROWS });
}

export function loadUserDetail(userId: string): Promise<UserDetail> {
  const entry = DEMO_PEOPLE.find((candidate) => candidate.id === userId);
  if (!entry) return Promise.reject(new Error(`Utilisateur ${userId} introuvable`));

  const index = DEMO_PEOPLE.indexOf(entry);
  const sponsor = index > 3 ? person(DEMO_PEOPLE[index % 4]!.id) : null;

  return demo({
    ...toRow(entry),
    phoneNumber: entry.phoneNumber,
    address: entry.city ? `${12 + (index % 40)} rue de la République, ${entry.city}` : null,
    onboardingStage: ONBOARDING_STAGES[index % ONBOARDING_STAGES.length]!,
    invitedBy: sponsor ? { id: sponsor.id, name: sponsor.fullName } : null,
    invitedCount: index % 5,
    referralCode: `ZEN-${entry.id.slice(-3)}${entry.fullName.slice(0, 2).toUpperCase()}`,
    sessions: entry.status === "ACTIVE" ? SESSIONS.slice(0, 1 + (index % 3)) : [],
    activity: ACTIVITY.slice(0, 2 + (index % 4)),
    moderation: index % 6 === 0 ? MODERATION : [],
  });
}
