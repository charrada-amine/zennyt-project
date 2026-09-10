package com.zennyt.games.domain.vo;

/**
 * Moitié de « J'investigue » réellement jouée.
 *
 * <p>Le jeu a été scindé en deux mini-jeux indépendants : l'empan de CHIFFRES
 * d'un côté, la mémoire des IMAGES de l'autre. Le mode voyage avec les mesures
 * parce que la validation et le barème en dépendent : une partie d'images
 * n'observe aucun chiffre et ne joue aucune restitution inversée, alors que
 * {@link MemoryQuestMetrics} exigeait jusqu'ici {@code observedDigits > 0} —
 * elle était donc rejetée à la soumission.
 */
public enum MemoryQuestMode {
    /** Chiffres seuls : empan direct, inverse, interférence. */
    DIGITS,

    /** Images seules : mémorisation d'objets, interférence visuelle, restitution. */
    IMAGES,

    /** Les deux missions à la suite — mode historique, valeur par défaut. */
    FULL;

    public boolean playsDigits() {
        return this != IMAGES;
    }

    public boolean playsImages() {
        return this != DIGITS;
    }
}
