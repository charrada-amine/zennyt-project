import { expect, test } from "bun:test";

import {
  matchesSearch,
  normalize,
  paginate,
  sortRows,
  toggleSort,
} from "../apps/console/src/lib/collections";

/* ── normalize / matchesSearch ─────────────────────────────────────────── */

test("normalize supprime la casse et les diacritiques", () => {
  expect(normalize("Amélie")).toBe("amelie");
  expect(normalize("CÔTE D'IVOIRE")).toBe("cote d'ivoire");
});

test("matchesSearch trouve un nom accentué depuis une saisie sans accent", () => {
  expect(matchesSearch(["Amélie Rousseau", "amelie@example.com"], "amelie")).toBe(true);
  expect(matchesSearch(["Amélie Rousseau"], "AMÉLIE")).toBe(true);
});

test("matchesSearch ignore les champs absents sans planter", () => {
  expect(matchesSearch([null, undefined, "Lyon"], "lyon")).toBe(true);
  expect(matchesSearch([null, undefined], "lyon")).toBe(false);
});

test("une recherche vide ou en espaces laisse tout passer", () => {
  expect(matchesSearch(["quoi que ce soit"], "")).toBe(true);
  expect(matchesSearch(["quoi que ce soit"], "   ")).toBe(true);
});

/* ── sortRows ──────────────────────────────────────────────────────────── */

interface Row {
  name: string;
  score: number;
  lastSeen: string | null;
}

const rows: Row[] = [
  { name: "Zoé", score: 10, lastSeen: null },
  { name: "amélie", score: 30, lastSeen: "2026-01-02" },
  { name: "Bruno", score: 20, lastSeen: "2026-03-04" },
];

const accessor = (row: Row, key: string) => (row as unknown as Record<string, unknown>)[key];

test("sans état de tri, l'ordre d'origine est conservé", () => {
  expect(sortRows(rows, null, accessor).map((row) => row.name)).toEqual([
    "Zoé",
    "amélie",
    "Bruno",
  ]);
});

test("le tri texte est insensible à la casse et aux accents", () => {
  const sorted = sortRows(rows, { key: "name", direction: "asc" }, accessor);
  expect(sorted.map((row) => row.name)).toEqual(["amélie", "Bruno", "Zoé"]);
});

test("le tri numérique compare des nombres, pas des chaînes", () => {
  const values = [{ n: 9 }, { n: 100 }, { n: 20 }];
  const sorted = sortRows(values, { key: "n", direction: "asc" }, (row, key) =>
    (row as unknown as Record<string, unknown>)[key],
  );
  expect(sorted.map((row) => row.n)).toEqual([9, 20, 100]);
});

test("les valeurs absentes tombent en fin de tri, dans les deux sens", () => {
  const asc = sortRows(rows, { key: "lastSeen", direction: "asc" }, accessor);
  expect(asc[asc.length - 1]?.lastSeen).toBeNull();
  const desc = sortRows(rows, { key: "lastSeen", direction: "desc" }, accessor);
  expect(desc[0]?.lastSeen).toBe("2026-03-04");
});

test("le tri est stable : à clé égale, l'ordre d'entrée est préservé", () => {
  const tied = [
    { id: "a", group: 1 },
    { id: "b", group: 1 },
    { id: "c", group: 1 },
  ];
  const sorted = sortRows(tied, { key: "group", direction: "asc" }, (row, key) =>
    (row as unknown as Record<string, unknown>)[key],
  );
  expect(sorted.map((row) => row.id)).toEqual(["a", "b", "c"]);
});

test("sortRows ne mute pas le tableau reçu", () => {
  const original = [...rows];
  sortRows(rows, { key: "name", direction: "asc" }, accessor);
  expect(rows).toEqual(original);
});

/* ── paginate ──────────────────────────────────────────────────────────── */

const items = Array.from({ length: 23 }, (_, index) => index + 1);

test("paginate découpe la page demandée et décrit les bornes", () => {
  const page = paginate(items, 2, 10);
  expect(page.rows).toEqual([11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
  expect(page).toMatchObject({ page: 2, pageCount: 3, total: 23, from: 11, to: 20 });
});

test("la dernière page peut être partielle", () => {
  const page = paginate(items, 3, 10);
  expect(page.rows).toEqual([21, 22, 23]);
  expect(page).toMatchObject({ from: 21, to: 23 });
});

test("une page hors bornes est ramenée dans les bornes plutôt que vide", () => {
  expect(paginate(items, 99, 10).page).toBe(3);
  expect(paginate(items, 0, 10).page).toBe(1);
  expect(paginate(items, -5, 10).rows).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
});

test("une collection vide reste sur une page 1 aux bornes nulles", () => {
  expect(paginate([], 1, 10)).toMatchObject({
    rows: [],
    page: 1,
    pageCount: 1,
    total: 0,
    from: 0,
    to: 0,
  });
});

/* ── toggleSort ────────────────────────────────────────────────────────── */

test("toggleSort bascule asc → desc sur la même colonne", () => {
  expect(toggleSort(null, "name")).toEqual({ key: "name", direction: "asc" });
  expect(toggleSort({ key: "name", direction: "asc" }, "name")).toEqual({
    key: "name",
    direction: "desc",
  });
  expect(toggleSort({ key: "name", direction: "desc" }, "name")).toEqual({
    key: "name",
    direction: "asc",
  });
});

test("changer de colonne repart en ascendant", () => {
  expect(toggleSort({ key: "name", direction: "desc" }, "score")).toEqual({
    key: "score",
    direction: "asc",
  });
});
