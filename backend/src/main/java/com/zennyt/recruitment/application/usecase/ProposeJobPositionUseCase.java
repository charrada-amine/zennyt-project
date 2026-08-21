package com.zennyt.recruitment.application.usecase;

import com.zennyt.shared.application.EmbeddingCodec;
import com.zennyt.recruitment.application.JobProfileTypeClassifier;
import com.zennyt.shared.application.port.EmbeddingPort;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.shared.application.exception.ConflictException;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Cas d'usage : un recruteur propose un métier absent du référentiel lors de
 * la création d'une offre. Le métier est immédiatement utilisable par
 * l'offre en cours (statut {@code PENDING_APPROVAL}), mais n'apparaît dans le
 * référentiel partagé (sélection des autres recruteurs) qu'une fois approuvé
 * par un admin — voir décision du 20/07.
 */
@Service
public class ProposeJobPositionUseCase {

    private final JobPositionRepository positions;
    private final EmbeddingPort embeddings;
    private final JobProfileTypeClassifier classifier;

    public ProposeJobPositionUseCase(JobPositionRepository positions, EmbeddingPort embeddings,
                                     JobProfileTypeClassifier classifier) {
        this.positions = positions;
        this.embeddings = embeddings;
        this.classifier = classifier;
    }

    public JobPosition execute(UUID recruiterId, String name, String sector) {
        if (positions.existsByNameAndSector(name, sector)) {
            throw new ConflictException("Ce métier existe déjà dans le référentiel");
        }
        float[] embeddingVector = embeddings.embed(name);
        String embedding = EmbeddingCodec.toJson(embeddingVector);
        var suggestedProfileType = classifier.suggest(embeddingVector);
        return positions.save(JobPosition.propose(name, sector, recruiterId, embedding, suggestedProfileType));
    }
}
