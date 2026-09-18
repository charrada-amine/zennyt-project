package com.zennyt.games.domain.vo;

/**
 * Condition d'un essai IST (Clark et al., 2006). La différence de comportement
 * entre les deux est l'information la plus riche de la tâche : échantillonner
 * davantage quand c'est gratuit, moins quand c'est coûteux.
 */
public enum IstCondition {
    /** Gain fixe : ouvrir des cases ne coûte rien. */
    FIXED_WIN,
    /** Gain décroissant : chaque case ouverte réduit le gain possible. */
    DECREASING_WIN
}
