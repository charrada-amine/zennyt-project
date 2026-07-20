package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;

import java.util.ArrayList;
import java.util.List;

/**
 * Générateur hors ligne — utilisé quand {@code GROQ_API_KEY} n'est pas
 * configurée (démo sans réseau, CI). Produit des questions génériques
 * clairement identifiables, jamais destinées à un vrai candidat.
 */
public class StubAssessmentGenerator implements AssessmentGeneratorPort {

    @Override
    public List<AssessmentQuestion> generate(GenerationSpec spec) {
        List<AssessmentQuestion> questions = new ArrayList<>(spec.questionCount());
        for (int i = 1; i <= spec.questionCount(); i++) {
            questions.add(new AssessmentQuestion(
                "[Question de démonstration %d/%d] Quelle réponse est correcte ?"
                    .formatted(i, spec.questionCount()),
                List.of("Réponse correcte", "Distracteur A", "Distracteur B", "Distracteur C"),
                0));
        }
        return questions;
    }
}
