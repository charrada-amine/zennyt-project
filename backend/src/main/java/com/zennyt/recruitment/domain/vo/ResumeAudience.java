package com.zennyt.recruitment.domain.vo;

/**
 * Public visé par un résumé IA (P5).
 *
 * <p>Le <b>fond est identique</b> dans les deux versions — mêmes forces, mêmes axes de
 * progression, mêmes données. Seule la formulation change : factuelle pour le recruteur,
 * ménageante et tournée vers la progression pour le candidat. Adoucir le fond, et pas
 * seulement le ton, produirait deux évaluations divergentes du même profil.
 */
public enum ResumeAudience {
    /** Analyse objective et factuelle, destinée à une décision de recrutement. */
    RECRUITER,
    /** Restitution diplomatique et motivante, destinée à la personne évaluée. */
    CANDIDATE
}
