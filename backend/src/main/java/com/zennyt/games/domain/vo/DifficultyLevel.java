package com.zennyt.games.domain.vo;

/**
 * Un niveau de difficulté d'« Emotional Radar v2 », à deux axes indépendants :
 * <ul>
 *   <li><b>charge cognitive</b> = nombre de choix proposés ({@code choicesCount}) ;</li>
 *   <li><b>finesse de discrimination</b> = proximité sémantique des choix
 *       ({@code targetDistance}).</li>
 * </ul>
 *
 * <p>Le niveau 3 isole la charge (beaucoup de choix, distance encore élevée) ; le
 * niveau 4 combine charge et finesse (beaucoup de choix, distance faible).
 *
 * @param level          numéro de niveau (1..4)
 * @param choicesCount   nombre de choix proposés (distracteurs + 1 bonne réponse)
 * @param targetDistance bande de proximité sémantique visée
 */
public record DifficultyLevel(int level, int choicesCount, DistanceBand targetDistance) {

    public DifficultyLevel {
        if (level < 1) {
            throw new IllegalArgumentException("level doit être ≥ 1 : " + level);
        }
        if (choicesCount < 2) {
            throw new IllegalArgumentException("choicesCount doit être ≥ 2 : " + choicesCount);
        }
        if (targetDistance == null) {
            throw new IllegalArgumentException("targetDistance requise");
        }
    }
}
