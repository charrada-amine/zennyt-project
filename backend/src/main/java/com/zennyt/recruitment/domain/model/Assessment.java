package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.AssessmentGenerationMode;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Agrégat Évaluation — banque de tests créés par le recruteur.
 *
 * <p>Peut être créée manuellement (avec des questions fournies) ou générée
 * par IA (mode FROM_FILE ou FROM_PROMPT). Chaque évaluation contient une liste
 * de questions MCQ à 4 options.
 */
public class Assessment extends AggregateRoot {

    private final UUID id;
    private final UUID createdByRecruiterId;
    private String title;
    private int timeLimitSeconds;
    private int maxQuestions;
    private AssessmentGenerationMode generationSource;
    private String shareableLink;
    private List<AssessmentQuestion> questions;
    private final Instant createdAt;

    private Assessment(UUID id, UUID createdByRecruiterId, String title) {
        this.id = id;
        this.createdByRecruiterId = createdByRecruiterId;
        this.title = title;
        this.questions = new ArrayList<>();
        this.createdAt = Instant.now();
    }

    /** Fabrique : crée une évaluation manuelle avec des questions. */
    public static Assessment createManual(UUID recruiterId, String title, int timeLimitSeconds,
                                          List<AssessmentQuestion> questions) {
        Assessment assessment = new Assessment(UUID.randomUUID(), recruiterId, title);
        assessment.timeLimitSeconds = timeLimitSeconds;
        assessment.questions = numbered(questions);
        assessment.maxQuestions = questions.size();
        assessment.generationSource = null; // création manuelle
        assessment.shareableLink = "https://www.zennyt.com/tests/" + assessment.id;
        return assessment;
    }

    /** Fabrique : crée une évaluation générée par IA (les questions seront ajoutées après). */
    public static Assessment createFromGeneration(UUID recruiterId, String title,
                                                   AssessmentGenerationMode mode, int numberOfQuestions) {
        Assessment assessment = new Assessment(UUID.randomUUID(), recruiterId, title);
        assessment.generationSource = mode;
        assessment.maxQuestions = numberOfQuestions;
        assessment.shareableLink = "https://www.zennyt.com/tests/" + assessment.id;
        return assessment;
    }

    /** Reconstruction depuis la persistance. */
    public static Assessment rehydrate(UUID id, UUID createdByRecruiterId, String title,
                                        int timeLimitSeconds, int maxQuestions,
                                        AssessmentGenerationMode generationSource,
                                        String shareableLink, List<AssessmentQuestion> questions,
                                        Instant createdAt) {
        Assessment assessment = new Assessment(id, createdByRecruiterId, title);
        assessment.timeLimitSeconds = timeLimitSeconds;
        assessment.maxQuestions = maxQuestions;
        assessment.generationSource = generationSource;
        assessment.shareableLink = shareableLink;
        assessment.questions = questions != null ? new ArrayList<>(questions) : new ArrayList<>();
        return assessment;
    }

    /**
     * Mise à jour partielle (recruteur propriétaire) : les paramètres {@code null}
     * sont laissés inchangés. Les questions fournies avec un id existant conservent
     * cet id (références externes stables) ; l'ordre est renuméroté.
     */
    public void update(String title, Integer timeLimitSeconds, List<AssessmentQuestion> questions) {
        if (title != null) this.title = title;
        if (timeLimitSeconds != null) this.timeLimitSeconds = timeLimitSeconds;
        if (questions != null) {
            this.questions = numbered(questions);
            this.maxQuestions = questions.size();
        }
    }

    /** Ajoute les questions générées par l'IA. */
    public void applyGeneratedQuestions(List<AssessmentQuestion> generated) {
        this.questions = numbered(generated);
        this.maxQuestions = generated.size();
    }

    /** Renumérote l'ordre des questions (1-based) sans toucher à leurs ids. */
    private static List<AssessmentQuestion> numbered(List<AssessmentQuestion> questions) {
        List<AssessmentQuestion> result = new ArrayList<>(questions.size());
        for (int i = 0; i < questions.size(); i++) {
            result.add(questions.get(i).withOrder(i + 1));
        }
        return result;
    }

    public UUID id() { return id; }
    public UUID createdByRecruiterId() { return createdByRecruiterId; }
    public String title() { return title; }
    public int timeLimitSeconds() { return timeLimitSeconds; }
    public int maxQuestions() { return maxQuestions; }
    public AssessmentGenerationMode generationSource() { return generationSource; }
    public String shareableLink() { return shareableLink; }
    public List<AssessmentQuestion> questions() { return List.copyOf(questions); }
    public Instant createdAt() { return createdAt; }
}
