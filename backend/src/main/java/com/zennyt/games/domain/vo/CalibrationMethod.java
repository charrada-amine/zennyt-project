package com.zennyt.games.domain.vo;

/**
 * Méthode de calibrage appareil (fiche « JE BOUGE » Tableau 2 révisé + guide).
 *
 * <p>{@link #TECHNIQUE} est la méthode <b>pure</b> retenue : elle sépare la
 * latence matérielle (affichage + traitement d'entrée) du temps de réaction
 * cognitif. La méthode « hybrid » des autres fiches est écartée (invalidée
 * méthodologiquement). {@link #HARDWARE_PROFILE_FALLBACK} n'utilise que le profil
 * matériel quand la mesure directe est indisponible → fiabilité réduite.
 */
public enum CalibrationMethod {
    TECHNIQUE("technique"),
    HARDWARE_PROFILE_FALLBACK("hardware_profile_fallback");

    private final String wire;

    CalibrationMethod(String wire) {
        this.wire = wire;
    }

    public String wire() {
        return wire;
    }
}
