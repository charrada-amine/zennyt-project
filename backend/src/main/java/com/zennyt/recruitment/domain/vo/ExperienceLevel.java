package com.zennyt.recruitment.domain.vo;

/**
 * Niveau d'expérience requis pour une offre — 4 bandes alignées sur la
 * matrice de pondération Fit Score (CdC Fit Score v3 §4.1, matrice v4.1).
 *
 * <p><b>Décision D-A du 2026-08-03 (FITSCORE_REMEDIATION.md §2, tâche F31)</b> —
 * retour à l'échelle du CdC. V29 avait renommé positionnellement les 4 bandes en
 * Junior/Mid/Senior/Executive pour suivre le contrat de la squad web ; le pic du
 * poids hard skills se retrouvait alors sur {@code MID}, et {@code SENIOR}
 * portait la pondération que le CdC destine à un Lead — en contradiction directe
 * avec le §4.1 (« Senior / Expert : hard skills dominant »).
 *
 * <p>Un recruteur qui sélectionne « Senior » obtient désormais bien le pic de
 * pondération technique (65 % sur un métier Technique), et non les 55 % d'un
 * poste de Lead.
 *
 * <p><b>Changement cassant d'API</b> — la valeur de {@code experienceLevel} change
 * dans toutes les requêtes et réponses. La squad web doit être prévenue avant
 * toute mise en production. Migration de reprise des données : V53.
 */
public enum ExperienceLevel {
    JUNIOR, SENIOR, LEAD, MANAGER
}
