package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;

/** Calcul déterministe pour les environnements sans clé Groq. */
public class StubFitScoreCalculator implements FitScoreCalculatorPort {
    @Override
    public FitScoreResult calculate(FitScoreInputs inputs) {
        int soft = inputs.softSkills().values().stream()
            .mapToInt(value -> (int) Math.round(value)).findFirst().orElse(0);
        int cv = inputs.cvText() == null || inputs.cvText().isBlank()
            ? 50 : 50 + Math.floorMod(inputs.cvText().hashCode(), 31);
        int context = Math.floorMod((String.valueOf(inputs.jobDescription())
            + String.valueOf(inputs.companyDescription())).hashCode(), 21);
        int score = bounded((soft * 40 + cv * 50 + context * 10) / 100);
        return new FitScoreResult(score, bounded(soft), bounded(cv));
    }

    private int bounded(int value) { return Math.max(0, Math.min(100, value)); }
}
