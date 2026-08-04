package com.zennyt.recruitment.application.port;

import com.zennyt.recruitment.domain.model.JobRoleProfile;

import java.util.Map;

/** Port interchangeable du calcul de compatibilité candidat/offre. */
public interface FitScoreCalculatorPort {
    /** @return {@code null} si la paire est incalculable (pas de pondération résolue). */
    FitScoreResult calculate(FitScoreInputs inputs);

    /**
     * <p>F22 — {@code jobDescription} et {@code companyDescription} ont été retirés.
     * Vestiges du moteur Groq supprimé, ils n'étaient plus lus par personne mais
     * coûtaient une lecture BDD par paire côté appelant. Surtout, les garder invitait
     * à s'en servir : le CdC §2 interdit explicitement que la description textuelle
     * libre pilote la pondération.
     *
     * @param roleProfile pondération résolue (profil métier × niveau) — {@code null} si
     *                    l'offre n'est reliée à aucun métier approuvé, auquel cas la paire
     *                    est incalculable (plus de repli IA, voir {@code FitScoreAiConfig})
     * @param hardSkillScore pourcentage de réussite au QCM, {@code null} si aucune tentative complétée
     * @param coverageRatio taux de couverture des jeux psychométriques (0-100, mécanisme 1 du CdC §3.3)
     */
    record FitScoreInputs(Map<String, Double> softSkills,
                          JobRoleProfile roleProfile, Integer hardSkillScore, int coverageRatio) {
        public FitScoreInputs {
            softSkills = softSkills == null ? Map.of() : Map.copyOf(softSkills);
        }
    }

    record FitScoreResult(int score, int softSkillScore) {}
}
