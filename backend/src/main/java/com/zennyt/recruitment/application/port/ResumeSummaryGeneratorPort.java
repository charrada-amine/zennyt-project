package com.zennyt.recruitment.application.port;

import java.util.Map;

/**
 * Port de génération des deux sections du résumé IA ("Resume AI") : soft
 * skills (à partir des scores par module psychométrique) et hard skills (CV +
 * résultat du test technique pour une offre). Même principe que
 * {@link FitScoreCalculatorPort} / {@code AssessmentGeneratorPort} : Groq
 * derrière ce port, stub hors ligne sans clé configurée.
 *
 * <p>Chaque génération est bilingue en un seul appel — "View original version"
 * bascule entre {@code fr} et {@code en} sans appel supplémentaire.
 */
public interface ResumeSummaryGeneratorPort {

    record BilingualText(String fr, String en) {}

    /** @param moduleScores libellé de module lisible -> score 0-100, jamais vide (appelant responsable) */
    BilingualText generateSoftSkillsSummary(Map<String, Integer> moduleScores);

    /** @param cvText peut être vide si aucune projection CV n'existe encore pour ce candidat */
    BilingualText generateHardSkillsSummary(String jobTitle, String cvText, int scorePercent, boolean passed);
}
