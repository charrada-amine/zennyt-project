package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;

import java.util.Map;
import java.util.stream.Collectors;

/** Générateur hors ligne — utilisé quand {@code GROQ_API_KEY} n'est pas configurée. */
public class StubResumeSummaryGenerator implements ResumeSummaryGeneratorPort {

    @Override
    public BilingualText generateSoftSkillsSummary(Map<String, Integer> moduleScores) {
        String modules = moduleScores.entrySet().stream()
            .map(e -> e.getKey() + " " + e.getValue() + "%")
            .collect(Collectors.joining(", "));
        return new BilingualText(
            "[Résumé de démonstration] Modules mesurés : " + modules + ".",
            "[Demo summary] Measured modules: " + modules + ".");
    }

    @Override
    public BilingualText generateHardSkillsSummary(String jobTitle, String cvText, int scorePercent, boolean passed) {
        return new BilingualText(
            "[Résumé de démonstration] Test pour « " + jobTitle + " » : " + scorePercent + "% ("
                + (passed ? "réussi" : "échoué") + ").",
            "[Demo summary] Test for \"" + jobTitle + "\": " + scorePercent + "% ("
                + (passed ? "passed" : "failed") + ").");
    }
}
