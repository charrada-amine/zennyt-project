/**
 * Helpers purs de recherche / tri / pagination.
 *
 * Aujourd'hui ils s'appliquent aux fixtures en mémoire. Le jour où les
 * endpoints `/admin/**` existent, ces mêmes valeurs (terme de recherche,
 * colonne triée, page) deviennent des paramètres de requête : les pages
 * appelantes ne bougent pas, seul l'endroit du calcul change.
 */

export type SortDirection = "asc" | "desc";

export interface SortState {
  key: string;
  direction: SortDirection;
}

export interface Page<T> {
  rows: T[];
  page: number;
  pageCount: number;
  total: number;
  /** Index 1-based du premier élément affiché, 0 si la page est vide. */
  from: number;
  /** Index 1-based du dernier élément affiché, 0 si la page est vide. */
  to: number;
}

/** Insensible à la casse et aux accents — « Amelie » trouve « Amélie ». */
export function normalize(value: string) {
  return value
    .toLocaleLowerCase("fr-FR")
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "");
}

export function matchesSearch(haystacks: Array<string | null | undefined>, query: string) {
  const needle = normalize(query.trim());
  if (!needle) return true;
  return haystacks.some((value) => (value ? normalize(value).includes(needle) : false));
}

function isEmpty(value: unknown) {
  return value === null || value === undefined || value === "";
}

function compare(a: unknown, b: unknown) {
  if (a === b) return 0;
  if (typeof a === "number" && typeof b === "number") return a - b;
  if (typeof a === "boolean" && typeof b === "boolean") return Number(a) - Number(b);
  return String(a).localeCompare(String(b), "fr-FR", { numeric: true, sensitivity: "base" });
}

/** Tri stable : deux lignes de même clé gardent leur ordre d'origine. */
export function sortRows<T>(
  rows: readonly T[],
  sort: SortState | null,
  accessor: (row: T, key: string) => unknown,
): T[] {
  if (!sort) return [...rows];
  const factor = sort.direction === "asc" ? 1 : -1;
  return rows
    .map((row, index) => ({ row, index }))
    .sort((left, right) => {
      const a = accessor(left.row, sort.key);
      const b = accessor(right.row, sort.key);
      // Les valeurs absentes tombent en fin de liste dans les DEUX sens : elles
      // ne sont pas « petites », elles sont hors classement. Le facteur de
      // direction ne doit donc pas s'y appliquer.
      if (isEmpty(a) || isEmpty(b)) {
        if (isEmpty(a) && isEmpty(b)) return left.index - right.index;
        return isEmpty(a) ? 1 : -1;
      }
      const result = compare(a, b);
      return result === 0 ? left.index - right.index : result * factor;
    })
    .map((entry) => entry.row);
}

/** Une page hors bornes est ramenée dans les bornes plutôt que de rendre du vide. */
export function paginate<T>(rows: readonly T[], page: number, pageSize: number): Page<T> {
  const total = rows.length;
  const pageCount = Math.max(1, Math.ceil(total / pageSize));
  const current = Math.min(Math.max(1, Math.trunc(page)), pageCount);
  const start = (current - 1) * pageSize;
  const slice = rows.slice(start, start + pageSize);
  return {
    rows: slice,
    page: current,
    pageCount,
    total,
    from: slice.length === 0 ? 0 : start + 1,
    to: start + slice.length,
  };
}

/** Bascule asc → desc → asc sur la même colonne, repart en asc sur une autre. */
export function toggleSort(current: SortState | null, key: string): SortState {
  if (current?.key !== key) return { key, direction: "asc" };
  return { key, direction: current.direction === "asc" ? "desc" : "asc" };
}
