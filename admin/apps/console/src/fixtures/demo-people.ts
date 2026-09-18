/**
 * ⚠️ PROVISOIRE — DONNÉES DE DÉMONSTRATION, PAS UN CONTRAT D'API ⚠️
 *
 * Population unique partagée par tous les espaces de la console, pour que les
 * renvois croisés soient cohérents : l'utilisateur qui apparaît dans la file
 * de modération est le même que celui de la liste Utilisateurs, et le parrain
 * d'une invitation existe bien dans la population.
 *
 * Tout le dossier `src/fixtures/` disparaît le jour où le contrat OpenAPI des
 * endpoints `/admin/**` est publié. Aucune forme de réponse backend n'est
 * supposée ici : ces objets décrivent ce que les écrans affichent.
 */

import type { UserRole, UserStatus } from "@/features/users/users-view";

const NOW = Date.now();
const DAY = 86_400_000;

/** Dates calculées au chargement du module : la démo reste toujours « fraîche ». */
export function daysAgo(days: number) {
  return new Date(NOW - days * DAY).toISOString();
}

export function daysAhead(days: number) {
  return new Date(NOW + days * DAY).toISOString();
}

export function hoursAgo(hours: number) {
  return new Date(NOW - hours * 3_600_000).toISOString();
}

export interface DemoPerson {
  id: string;
  fullName: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  emailVerified: boolean;
  city: string | null;
  country: string | null;
  registeredDaysAgo: number;
  lastSeenDaysAgo: number | null;
  profileCompletion: number;
  phoneNumber: string | null;
}

/* eslint-disable */
// prettier-ignore
const RAW: Array<[string, string, UserRole, UserStatus, boolean, string | null, string | null, number, number | null, number, string | null]> = [
  ["Amélie Rousseau", "amelie.rousseau@example.com", "CANDIDATE", "ACTIVE", true, "Lyon", "France", 4, 0, 92, "+33 6 12 34 56 78"],
  ["Karim Benali", "karim.benali@example.com", "CANDIDATE", "ACTIVE", true, "Marseille", "France", 9, 1, 78, "+33 6 22 11 90 45"],
  ["Sofia Marchetti", "sofia.marchetti@example.com", "RECRUITER", "ACTIVE", true, "Paris", "France", 62, 0, 100, "+33 7 45 88 20 11"],
  ["Thomas Lefèvre", "thomas.lefevre@example.com", "STUDENT", "ACTIVE", false, "Nantes", "France", 2, 0, 41, null],
  ["Ngozi Okafor", "ngozi.okafor@example.com", "CANDIDATE", "ACTIVE", true, "Bruxelles", "Belgique", 27, 3, 86, "+32 470 11 22 33"],
  ["Lucas Ferreira", "lucas.ferreira@example.com", "CANDIDATE", "DEACTIVATED", true, "Porto", "Portugal", 140, 44, 63, null],
  ["Inès Haddad", "ines.haddad@example.com", "STUDENT", "ACTIVE", true, "Tunis", "Tunisie", 18, 2, 70, "+216 22 118 900"],
  ["Julien Moreau", "julien.moreau@example.com", "RECRUITER", "ACTIVE", true, "Lille", "France", 88, 1, 100, "+33 6 78 45 12 09"],
  ["Fatou Diallo", "fatou.diallo@example.com", "CANDIDATE", "ACTIVE", true, "Dakar", "Sénégal", 33, 5, 81, null],
  ["Mateo Rodríguez", "mateo.rodriguez@example.com", "CANDIDATE", "ACTIVE", false, "Madrid", "Espagne", 1, 0, 22, null],
  ["Clara Dubois", "clara.dubois@example.com", "STUDENT", "ACTIVE", true, "Bordeaux", "France", 51, 8, 58, "+33 6 90 33 21 47"],
  ["Yassine Cherif", "yassine.cherif@example.com", "CANDIDATE", "ACTIVE", true, "Casablanca", "Maroc", 12, 0, 74, "+212 6 61 22 08 14"],
  ["Élodie Garnier", "elodie.garnier@example.com", "RECRUITER", "ACTIVE", true, "Paris", "France", 205, 2, 100, "+33 6 14 77 32 65"],
  ["Hugo Bertrand", "hugo.bertrand@example.com", "CANDIDATE", "DELETED", true, "Toulouse", "France", 310, 190, 48, null],
  ["Aya Nakamura", "aya.nakamura@example.com", "STUDENT", "ACTIVE", true, "Lyon", "France", 6, 1, 66, null],
  ["Pierre Lemaitre", "pierre.lemaitre@example.com", "CANDIDATE", "ACTIVE", true, "Rennes", "France", 74, 12, 89, "+33 6 55 41 78 23"],
  ["Sarah Cohen", "sarah.cohen@example.com", "RECRUITER", "ACTIVE", true, "Genève", "Suisse", 119, 0, 95, "+41 78 220 11 44"],
  ["Emeka Chukwu", "emeka.chukwu@example.com", "CANDIDATE", "ACTIVE", false, "Abidjan", "Côte d'Ivoire", 3, 2, 35, null],
  ["Camille Perrin", "camille.perrin@example.com", "CANDIDATE", "ACTIVE", true, "Grenoble", "France", 40, 6, 77, "+33 6 33 90 14 52"],
  ["Rania Belkacem", "rania.belkacem@example.com", "STUDENT", "ACTIVE", true, "Alger", "Algérie", 21, 4, 62, null],
  ["Nicolas Girard", "nicolas.girard@example.com", "CANDIDATE", "DEACTIVATED", true, "Strasbourg", "France", 160, 61, 55, null],
  ["Léa Fontaine", "lea.fontaine@example.com", "CANDIDATE", "ACTIVE", true, "Montpellier", "France", 15, 1, 84, "+33 6 71 20 88 39"],
  ["Omar Zidane", "omar.zidane@example.com", "RECRUITER", "ACTIVE", true, "Paris", "France", 96, 3, 98, "+33 6 40 55 27 18"],
  ["Manon Leroy", "manon.leroy@example.com", "STUDENT", "ACTIVE", false, "Nice", "France", 5, 0, 29, null],
  ["Adama Traoré", "adama.traore@example.com", "CANDIDATE", "ACTIVE", true, "Bamako", "Mali", 47, 9, 72, null],
  ["Sophie Renard", "sophie.renard@example.com", "CANDIDATE", "ACTIVE", true, "Lyon", "France", 29, 2, 90, "+33 6 25 60 13 84"],
  ["Antoine Mercier", "antoine.mercier@example.com", "CANDIDATE", "ACTIVE", true, "Paris", "France", 8, 0, 68, null],
  ["Nadia Slimani", "nadia.slimani@example.com", "ADMIN", "ACTIVE", true, "Paris", "France", 420, 0, 100, "+33 6 09 88 44 21"],
];
/* eslint-enable */

export const DEMO_PEOPLE: DemoPerson[] = RAW.map((entry, index) => ({
  id: `usr_${String(index + 1).padStart(3, "0")}`,
  fullName: entry[0],
  email: entry[1],
  role: entry[2],
  status: entry[3],
  emailVerified: entry[4],
  city: entry[5],
  country: entry[6],
  registeredDaysAgo: entry[7],
  lastSeenDaysAgo: entry[8],
  profileCompletion: entry[9],
  phoneNumber: entry[10],
}));

export function person(id: string): DemoPerson {
  const found = DEMO_PEOPLE.find((entry) => entry.id === id);
  if (!found) throw new Error(`Fixture introuvable : ${id}`);
  return found;
}

/** Raccourci pour les renvois croisés (auteur signalé, parrain, invitant…). */
export function personRef(id: string) {
  const found = person(id);
  return { id: found.id, name: found.fullName, email: found.email };
}

/**
 * Série pseudo-aléatoire déterministe : même graphique à chaque rendu, pas de
 * scintillement entre deux navigations.
 */
export function series(count: number, base: number, spread: number, seed: number) {
  let state = seed;
  return Array.from({ length: count }, (_, index) => {
    state = (state * 1103515245 + 12345) % 2147483648;
    const noise = (state / 2147483648 - 0.5) * spread;
    const growth = (index / Math.max(count - 1, 1)) * base * 0.45;
    return Math.max(0, Math.round(base + growth + noise));
  });
}

/** Étiquettes d'abscisse « 12 sept. » pour les N derniers jours. */
export function dayLabels(count: number) {
  const format = new Intl.DateTimeFormat("fr-FR", { day: "numeric", month: "short" });
  return Array.from({ length: count }, (_, index) =>
    format.format(new Date(NOW - (count - 1 - index) * DAY)),
  );
}
