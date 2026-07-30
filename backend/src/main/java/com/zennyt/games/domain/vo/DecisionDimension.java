package com.zennyt.games.domain.vo;

/**
 * Dimension cognitive évaluée par « Je Décide » (prise de décision).
 *
 * <p><b>Couche MOTEUR (définitive, fiche « JE DÉCIDE »)</b> : 5 capacités, 6 items
 * chacune, chaque dimension notée /18. Ces 5 dimensions sont figées par la fiche.
 */
public enum DecisionDimension {
    /** Identification / analyse de l'information (II). */
    II,
    /** Régulation émotionnelle dans la décision (ER). */
    ER,
    /** Décision sous temps — seule dimension dont le score dépend du temps (DT). */
    DT,
    /** Cohérence & stabilité — format en paires liées (CS). */
    CS,
    /** Responsabilité / engagement de la décision (RE). */
    RE
}
