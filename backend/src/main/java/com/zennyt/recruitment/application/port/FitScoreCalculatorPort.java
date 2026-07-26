package com.zennyt.recruitment.application.port;

import com.zennyt.recruitment.domain.model.JobRoleProfile;

import java.util.Map;

/** Port interchangeable du calcul de compatibilité candidat/offre. */
public interface FitScoreCalculatorPort {
    FitScoreResult calculate(FitScoreInputs inputs);

    /**
     * @param roleProfile pondération résolue (profil métier × niveau) — {@code null}
     *                    si l'offre n'est pas encore reliée au référentiel de métiers
     *                    (repli sur le moteur IA, pas de dégradation pour les offres existantes)
     * @param hardSkillScore pourcentage de réussite au QCM, {@code null} si aucune tentative complétée
     * @param coverageRatio taux de couverture des jeux psychométriques (0-100, mécanisme 1 du CdC §3.3)
     */
    record FitScoreInputs(Map<String, Double> softSkills, String cvText,
                          String jobDescription, String companyDescription,
                          JobRoleProfile roleProfile, Integer hardSkillScore, int coverageRatio) {
        public FitScoreInputs {
            softSkills = softSkills == null ? Map.of() : Map.copyOf(softSkills);
        }
    }

    record FitScoreResult(int score, int softSkillScore, int cvMatchScore) {}
}
