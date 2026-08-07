package com.zennyt.recruitment.application.port;

import com.zennyt.recruitment.domain.model.AssessmentQuestion;

import java.util.List;

/**
 * Port de génération de questions d'évaluation par IA — même principe que
 * {@link FitScoreCalculatorPort} : interchangeable, implémenté par l'adaptateur
 * Groq en {@code infrastructure.ai} ou par un stub hors ligne sans clé configurée.
 *
 * <p>Une seule méthode sert les deux tunnels de génération (fichier source ou
 * description libre) : dans les deux cas, l'appelant réduit son entrée à un
 * texte source ({@code sourceText}) avant d'appeler le port.
 */
public interface AssessmentGeneratorPort {

    /**
     * @param sourceText    texte à partir duquel générer les questions — description
     *                      de poste libre, ou texte extrait d'un fichier uploadé
     * @param questionCount nombre de questions demandées
     * @param language      langue des questions (défaut : fr)
     */
    record GenerationSpec(String sourceText, int questionCount, String language) {}

    /**
     * Génère des questions MCQ (4 options, 1 seule correcte). Les invariants
     * sont garantis par {@link AssessmentQuestion} — toute sortie IA invalide
     * doit être rejetée par l'adaptateur, jamais propagée.
     */
    List<AssessmentQuestion> generate(GenerationSpec spec);
}
