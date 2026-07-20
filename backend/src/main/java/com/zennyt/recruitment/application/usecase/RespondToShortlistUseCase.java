package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : le candidat répond à une présélection (SHORTLISTED -> APPROVED/REJECTED).
 *
 * <p>Contrepartie candidat de {@link ChangeApplicationStatusUseCase} — voir décision du 20/07 :
 * le recruteur présélectionne, seul le candidat décide de la suite.
 */
@Service
@Transactional
public class RespondToShortlistUseCase {

    private final ApplicationRepository repository;

    public RespondToShortlistUseCase(ApplicationRepository repository) {
        this.repository = repository;
    }

    public Application execute(UUID applicationId, UUID candidateId, boolean approve) {
        Application app = repository.findById(applicationId)
            .orElseThrow(() -> new NotFoundException("Candidature introuvable"));
        if (!app.candidateId().equals(candidateId)) {
            throw new ForbiddenException("Cette candidature ne vous appartient pas");
        }
        if (app.status() != ApplicationStatus.SHORTLISTED) {
            throw new IllegalStateException("Cette candidature n'est pas en attente de votre réponse");
        }
        app.changeStatus(approve ? ApplicationStatus.APPROVED : ApplicationStatus.REJECTED);
        return repository.save(app);
    }
}
