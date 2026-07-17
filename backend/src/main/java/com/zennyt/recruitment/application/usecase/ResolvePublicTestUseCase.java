package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Résout le token d'un lien de test partagé. */
@Service
@Transactional(readOnly = true)
public class ResolvePublicTestUseCase {
    private final AssessmentRepository assessments;

    public ResolvePublicTestUseCase(AssessmentRepository assessments) {
        this.assessments = assessments;
    }

    public Assessment execute(String token) {
        final UUID assessmentId;
        try {
            assessmentId = UUID.fromString(token);
        } catch (IllegalArgumentException exception) {
            throw new NotFoundException("Test introuvable");
        }
        return assessments.findById(assessmentId)
            .orElseThrow(() -> new NotFoundException("Test introuvable"));
    }
}
