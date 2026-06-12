package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.command.SubmitApplicationCommand;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Use case : soumettre une candidature.
 *
 * <p>Orchestre le flux applicatif sans contenir de logique métier (celle-ci
 * est dans l'agrégat) :
 * <ol>
 *   <li>vérifie la règle d'unicité (pas deux fois la même offre) ;</li>
 *   <li>crée l'agrégat (qui enregistre son événement) ;</li>
 *   <li>persiste ;</li>
 *   <li>publie les événements de domaine sur l'event bus interne.</li>
 * </ol>
 *
 * <p>La publication post-persistance garantit qu'aucun événement n'est émis si
 * la transaction échoue.
 */
@Service
public class SubmitApplicationUseCase {

    private final ApplicationRepository repository;
    private final ApplicationEventPublisher eventPublisher;

    public SubmitApplicationUseCase(ApplicationRepository repository,
                                    ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public Application execute(SubmitApplicationCommand command) {
        if (repository.existsByCandidateIdAndJobId(command.candidateId(), command.jobId())) {
            throw new IllegalStateException("Candidature déjà existante pour cette offre");
        }

        Application application = Application.submit(
            command.candidateId(), command.jobId(), command.coverLetter());

        Application saved = repository.save(application);

        // Publication des Domain Events après persistance réussie
        saved.domainEvents().forEach(eventPublisher::publishEvent);
        saved.clearEvents();

        return saved;
    }
}
