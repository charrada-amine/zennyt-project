package com.zennyt.recruitment.application.port;

import java.util.Map;

/** Port interchangeable du calcul de compatibilité candidat/offre. */
public interface FitScoreCalculatorPort {
    FitScoreResult calculate(FitScoreInputs inputs);

    record FitScoreInputs(Map<String, Double> softSkills, String cvText,
                          String jobDescription, String companyDescription) {
        public FitScoreInputs {
            softSkills = softSkills == null ? Map.of() : Map.copyOf(softSkills);
        }
    }

    record FitScoreResult(int score, int softSkillScore, int cvMatchScore) {}
}
