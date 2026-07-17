package com.zennyt.recruitment.domain.model;

import java.util.List;
import java.util.UUID;

/**
 * Question d'évaluation MCQ — value object embarqué dans {@link Assessment}.
 *
 * <p>Chaque question a exactement 4 options et un index (0-3) de réponse correcte.
 * L'{@code id} est généré côté serveur et reste stable lors des mises à jour
 * (les résultats de candidats peuvent y faire référence) ; l'{@code order}
 * (1-based) est attribué par l'agrégat {@link Assessment}.
 */
public record AssessmentQuestion(
    UUID id,
    int order,
    String text,
    List<String> options,
    int correctOptionIndex
) {
    public AssessmentQuestion {
        if (id == null) id = UUID.randomUUID();
        if (text == null || text.isBlank()) throw new IllegalArgumentException("Le texte de la question est obligatoire");
        if (options == null || options.size() != 4) throw new IllegalArgumentException("Exactement 4 options requises");
        if (correctOptionIndex < 0 || correctOptionIndex >= options.size())
            throw new IllegalArgumentException("L'index correct doit être entre 0 et " + (options.size() - 1));
    }

    /** Nouvelle question sans id (généré) ni ordre (attribué par l'agrégat). */
    public AssessmentQuestion(String text, List<String> options, int correctOptionIndex) {
        this(null, 0, text, options, correctOptionIndex);
    }

    AssessmentQuestion withOrder(int order) {
        return new AssessmentQuestion(id, order, text, options, correctOptionIndex);
    }
}
