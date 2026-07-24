package com.zennyt.recruitment.domain.vo;

/**
 * Niveau d'expérience requis pour une offre — 4 bandes alignées sur la
 * matrice de pondération Fit Score (voir PLAN_FITSCORE_V3.md décision D8).
 * Renommées Junior/Mid/Senior/Executive (contrat squad web, §3) ; la
 * matrice et les libellés par métier restent les mêmes 4 bandes, dans le
 * même ordre — seul le nom de chaque bande a changé (JUNIOR inchangé,
 * ex-SENIOR devient MID, ex-LEAD devient SENIOR, ex-MANAGER devient EXECUTIVE).
 */
public enum ExperienceLevel {
    JUNIOR, MID, SENIOR, EXECUTIVE
}
