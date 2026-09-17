/**
 * ═══════════════════════════════════════════════════════════════════════════
 * POINT DE BASCULE UNIQUE MOCK → API
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Chaque page consomme ses données via `useConsoleData(clé, chargeur)`, où le
 * chargeur a la signature définitive `() => Promise<T>`.
 *
 * Aujourd'hui, les chargeurs vivent dans les fichiers `*-fixtures.ts` et
 * renvoient `demo(valeurEnDur)` — une promesse résolue après une latence
 * simulée, pour que les squelettes de chargement et les états d'erreur soient
 * du vrai code exercé, pas de la décoration.
 *
 * Le jour où le contrat OpenAPI des endpoints `/admin/**` est publié :
 *   1. écrire `<domaine>-api.ts` (fetch + mapping vers les types de vue) ;
 *   2. remplacer l'import `*-fixtures` par `*-api` dans la page ;
 *   3. supprimer le fichier de fixtures.
 * Aucune page, aucun composant, aucun type de vue ne change.
 *
 * Aucune forme d'API n'est inventée ici : les fixtures décrivent ce dont
 * l'écran a besoin, pas ce que le backend renverra.
 */

import { useCallback, useEffect, useRef, useState } from "react";

/** PROVISOIRE — latence simulée, à supprimer avec les fixtures. */
export const DEMO_LATENCY_MS = 280;

/** Vrai tant que la console sert des fixtures. Pilote le bandeau « démonstration ». */
export const DEMO_MODE = true;

/** Enveloppe une valeur en dur dans la signature définitive du chargeur. */
export function demo<T>(value: T): Promise<T> {
  return new Promise((resolve) => {
    setTimeout(() => resolve(value), DEMO_LATENCY_MS);
  });
}

export interface ConsoleQuery<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
}

/**
 * `key` identifie la ressource (ex. `users`, `users/42`) : elle change quand on
 * navigue vers une autre ressource et relance le chargement. `load` est lue via
 * une ref pour qu'un chargeur défini en ligne ne déclenche pas de boucle.
 */
export function useConsoleData<T>(key: string, load: () => Promise<T>): ConsoleQuery<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);
  const loadRef = useRef(load);
  loadRef.current = load;

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    loadRef
      .current()
      .then((value) => {
        if (active) setData(value);
      })
      .catch((cause: unknown) => {
        if (!active) return;
        setData(null);
        setError(cause instanceof Error ? cause.message : "Chargement impossible");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [key, attempt]);

  const reload = useCallback(() => setAttempt((value) => value + 1), []);
  return { data, loading, error, reload };
}
