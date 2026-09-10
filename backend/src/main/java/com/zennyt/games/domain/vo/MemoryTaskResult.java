package com.zennyt.games.domain.vo;

/**
 * Résultat mesuré d'UNE tâche « J'investigue » (une instance de niveau).
 *
 * <p>Mesures brutes — jamais de points. Le domaine note la justesse du rappel
 * ({@code correct/total}) et applique le timeout ajusté du calibrage : une tâche
 * dont {@code responseTimeMs} dépasse {@code max_task_time_ms + offset} est un
 * échec par dépassement de temps (note de rappel voidée).
 *
 * @param kind           type de tâche
 * @param correct        éléments rappelés correctement (≥ 0, ≤ total)
 * @param total          éléments à rappeler (≥ 0)
 * @param responseTimeMs temps brut de la tâche (le timeout est décidé serveur)
 * @param level          niveau qui a produit la tâche (≥ 1) — fixe le délai
 *                       applicable à une tâche PARASITE, dont le budget dépend
 *                       du niveau, contrairement aux tâches de rappel qui
 *                       partagent un seuil unique
 */
public record MemoryTaskResult(
    MemoryTaskKind kind,
    int correct,
    int total,
    int responseTimeMs,
    int level
) {
    public MemoryTaskResult {
        if (kind == null) {
            throw new IllegalArgumentException("kind est requis");
        }
        if (total < 0) {
            throw new IllegalArgumentException("total doit être >= 0");
        }
        if (correct < 0 || correct > total) {
            throw new IllegalArgumentException("correct doit être dans [0, total]");
        }
        if (responseTimeMs < 0) {
            throw new IllegalArgumentException("responseTimeMs doit être >= 0");
        }
        if (level < 1) {
            level = 1; // mesures d'un client antérieur au champ
        }
    }

    /** Compatibilité : tâche sans niveau explicite (mesures historiques). */
    public MemoryTaskResult(MemoryTaskKind kind, int correct, int total, int responseTimeMs) {
        this(kind, correct, total, responseTimeMs, 1);
    }

    /** Justesse du rappel [0,1] (indépendante du timeout). */
    public double accuracy() {
        return total == 0 ? 0.0 : correct / (double) total;
    }
}
