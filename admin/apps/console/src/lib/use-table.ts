import { useEffect, useMemo, useState } from "react";

import { type Page, type SortState, paginate, sortRows, toggleSort } from "./collections";

export const DEFAULT_PAGE_SIZE = 8;

export interface TableConfig<T> {
  /** Valeur comparable pour une colonne triable. */
  sortValue: (row: T, key: string) => unknown;
  initialSort?: SortState;
  pageSize?: number;
}

export interface TableResult<T> {
  page: Page<T>;
  sort: SortState | null;
  onSort: (key: string) => void;
  goToPage: (page: number) => void;
}

/**
 * Tri et pagination côté client des lignes déjà filtrées par la page appelante.
 * La page revient à 1 dès que le jeu de lignes change, sinon un filtre
 * restrictif laisserait l'utilisateur sur une page vide.
 */
export function useTable<T>(rows: readonly T[], config: TableConfig<T>): TableResult<T> {
  const { sortValue, initialSort, pageSize = DEFAULT_PAGE_SIZE } = config;
  const [sort, setSort] = useState<SortState | null>(initialSort ?? null);
  const [page, setPage] = useState(1);

  useEffect(() => {
    setPage(1);
  }, [rows]);

  const sorted = useMemo(() => sortRows(rows, sort, sortValue), [rows, sort, sortValue]);
  const current = useMemo(() => paginate(sorted, page, pageSize), [sorted, page, pageSize]);

  return {
    page: current,
    sort,
    onSort: (key: string) => {
      setSort((previous) => toggleSort(previous, key));
      setPage(1);
    },
    goToPage: setPage,
  };
}
