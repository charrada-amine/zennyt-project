package com.zennyt.recruitment.domain.vo;

/** Mode de génération d'une évaluation. */
public enum AssessmentGenerationMode {
    /** Upload d'un fichier PDF ou MCQ existant. */
    FROM_FILE,
    /** Description textuelle du poste — l'IA génère les questions. */
    FROM_PROMPT
}
