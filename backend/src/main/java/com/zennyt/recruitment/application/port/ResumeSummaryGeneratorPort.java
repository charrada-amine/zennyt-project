package com.zennyt.recruitment.application.port;

import com.zennyt.recruitment.domain.vo.HardSkillTrend;
import com.zennyt.recruitment.domain.vo.ResumeAudience;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * Port de génération des deux sections du résumé IA ("Resume AI") : soft skills (à partir
 * des scores par module psychométrique) et hard skills (CV + historique des tests
 * techniques du candidat sur un métier). Même principe que {@link FitScoreCalculatorPort} /
 * {@code AssessmentGeneratorPort} : Groq derrière ce port, stub hors ligne sans clé
 * configurée.
 *
 * <p>Chaque génération est bilingue en un seul appel — "View original version" bascule
 * entre {@code fr} et {@code en} sans appel supplémentaire. Le <b>public</b>, lui, exige un
 * appel par version : le modèle ne peut pas produire deux registres différents en une
 * réponse sans que l'un des deux se dégrade.
 */
public interface ResumeSummaryGeneratorPort {

    record BilingualText(String fr, String en) {}

    /**
     * Un test noté, tel que le résumé le voit.
     *
     * <p>{@code experienceLevel} est le niveau de l'offre <b>source</b> : la difficulté d'un
     * QCM n'étant modélisée nulle part, c'est la seule indication disponible sur le calibre
     * d'un test emprunté à une autre offre (D5).
     */
    record HardSkillTestRecap(int percentage, boolean passed, Instant completedAt,
                              String experienceLevel) {}

    /**
     * Tout ce dont le générateur a besoin pour la section hard skills.
     *
     * <p>Regroupé en un objet plutôt qu'en cinq paramètres : la liste est destinée à
     * s'enrichir (compétences du CV structurées, contenu du QCM…) et chaque ajout aurait
     * modifié la signature des deux implémentations et de tous les tests.
     *
     * @param history du plus récent au plus ancien, jamais vide (appelant responsable)
     * @param trend   <b>calculé en amont, jamais déduit par le modèle</b> — voir
     *                {@link HardSkillTrend}
     */
    record HardSkillsContext(String jobPositionName, String cvText,
                             List<HardSkillTestRecap> history, HardSkillTrend trend) {}

    /** @param moduleScores libellé de module lisible -> score 0-100, jamais vide (appelant responsable) */
    BilingualText generateSoftSkillsSummary(Map<String, Integer> moduleScores, ResumeAudience audience);

    /**
     * Résumé hard skills d'un candidat sur un <b>métier</b>, plus sur une offre (D1).
     *
     * <p>Reçoit l'historique complet et non une moyenne : le résumé doit pouvoir parler de
     * trajectoire, ce qu'un nombre isolé ne permet pas. Il ne doit pas pour autant
     * <b>affirmer un score agrégé</b> : le nombre montré au recruteur est celui du Fit
     * Score, qui est par offre et applique la règle du test propre au rang 1 — un chiffre
     * asséné ici le contredirait.
     */
    BilingualText generateHardSkillsSummary(HardSkillsContext context, ResumeAudience audience);
}
