package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
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

    public ProposeJobPositionUseCase(JobPositionRepository positions) {
        this.positions = positions;
    }

    public JobPosition execute(UUID recruiterId, String name, String sector) {
        return positions.save(JobPosition.propose(name, sector, recruiterId));
    }
}
