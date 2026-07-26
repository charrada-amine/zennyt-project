package com.zennyt.recruitment.domain.vo;

/**
 * Mode de mesure du hard skills d'un profil métier (Couche A, CdC Fit Score v3
 * §4.3) — QCM pour la majorité des profils ; Portfolio/Mixte réservés au
 * profil ARTISTIQUE, dont le hard skills n'est pas toujours mesurable par un
 * QCM automatique classique.
 */
public enum TypeEvaluationHard {
    QCM, PORTFOLIO, MIXTE
}
