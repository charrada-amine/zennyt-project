package com.zennyt.recruitment.domain.vo;

/**
 * Niveau d'alerte « hard skills manquant » (CdC Fit Score v3 §6) — purement
 * informationnel, jamais utilisé dans le calcul du Fit Score.
 *
 * <p><b>F19 (FITSCORE_REMEDIATION.md §3 index F19, décision D-B).</b>
 * {@code PORTFOLIO_BASED} distingue le cas ARTISTIQUE — « pas de QCM, c'est le
 * fonctionnement normal, évaluation par portfolio » — du cas générique
 * {@code INFO} — « pas de QCM, pensez à en ajouter un ». Avant ce correctif
 * les deux partageaient le même jeton {@code INFO} : un client ne pouvait pas
 * les distinguer, alors que le CdC §6 insiste sur le fait que le cas
 * Artistique « n'est pas une anomalie à signaler comme un oubli ».
 */
public enum HardSkillsAlertLevel {
    NONE, INFO, MODERATE, STRONG, PORTFOLIO_BASED
}
