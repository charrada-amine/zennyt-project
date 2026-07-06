package com.zennyt.games.domain.vo;

/**
 * Règle active sur un essai de « Je bouge / Move Fast ».
 *
 * <p>La flexibilité cognitive est mesurée par la capacité à basculer entre ces
 * deux règles : {@link #ORIENTATION} (suivre le nez de l'avion) et
 * {@link #MOVEMENT} (suivre la direction du mouvement).
 */
public enum MoveFastRule {
    ORIENTATION,
    MOVEMENT
}
