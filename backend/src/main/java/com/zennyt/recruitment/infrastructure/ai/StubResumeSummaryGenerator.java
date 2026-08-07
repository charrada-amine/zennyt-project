package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.domain.vo.ResumeAudience;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Générateur hors ligne — utilisé quand {@code GROQ_API_KEY} n'est pas configurée.
 *
 * <p>Distingue lui aussi les deux publics : sans cela, la recette de la double version
 * (les 4 résumés d'un candidat) ne serait vérifiable qu'avec une clé Groq valide.
 */
public class StubResumeSummaryGenerator implements ResumeSummaryGeneratorPort {

    @Override
    public BilingualText generateSoftSkillsSummary(Map<String, Integer> moduleScores, ResumeAudience audience) {
        String modules = moduleScores.entrySet().stream()
            .map(e -> e.getKey() + " " + e.getValue() + "%")
            .collect(Collectors.joining(", "));
        if (audience == ResumeAudience.CANDIDATE) {
            return new BilingualText(
                "[Résumé de démonstration — version candidat] Vos résultats : " + modules
                    + ". Ces compétences se développent avec l'entraînement.",
                "[Demo summary — candidate version] Your results: " + modules
                    + ". These skills develop with practice.");
        }
        return new BilingualText(
            "[Résumé de démonstration — version recruteur] Modules mesurés : " + modules + ".",
            "[Demo summary — recruiter version] Measured modules: " + modules + ".");
    }

    @Override
    public BilingualText generateHardSkillsSummary(HardSkillsContext context, ResumeAudience audience) {
        List<HardSkillTestRecap> history = context.history();
        HardSkillTestRecap dernier = history.get(0);
        String parcours = history.stream()
            .map(test -> test.percentage() + "%")
            .collect(Collectors.joining(" ← "));
        // La tendance apparaît telle qu'elle a été calculée : c'est elle que la recette
        // vérifie, et le stub ne doit pas pouvoir la contredire là où le modèle le pourrait.
        String tendance = context.trend().name();
        if (audience == ResumeAudience.CANDIDATE) {
            return new BilingualText(
                "[Résumé de démonstration — version candidat] Vos tests sur « "
                    + context.jobPositionName() + " » : " + parcours
                    + " (du plus récent au plus ancien). Tendance : " + tendance + ".",
                "[Demo summary — candidate version] Your tests for \"" + context.jobPositionName()
                    + "\": " + parcours + " (most recent first). Trend: " + tendance + ".");
        }
        return new BilingualText(
            "[Résumé de démonstration — version recruteur] " + history.size() + " test(s) sur « "
                + context.jobPositionName() + " » : " + parcours + ". Dernier résultat "
                + (dernier.passed() ? "réussi" : "échoué") + ". Tendance : " + tendance + ".",
            "[Demo summary — recruiter version] " + history.size() + " test(s) for \""
                + context.jobPositionName() + "\": " + parcours + ". Latest outcome "
                + (dernier.passed() ? "passed" : "failed") + ". Trend: " + tendance + ".");
    }
}
