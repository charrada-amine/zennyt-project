package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;

import java.util.UUID;

/** Cas d'usage : un admin approuve ou rejette un métier proposé par un recruteur. */
@Service
public class ReviewJobPositionUseCase {

    private final JobPositionRepository positions;

    public ReviewJobPositionUseCase(JobPositionRepository positions) {
        this.positions = positions;
    }

    public JobPosition approve(UUID id, JobProfileType profileType) {
        JobPosition position = find(id);
        position.approve(profileType);
        return positions.save(position);
    }

    public JobPosition reject(UUID id) {
        JobPosition position = find(id);
        position.reject();
        return positions.save(position);
    }

    private JobPosition find(UUID id) {
        return positions.findById(id).orElseThrow(() -> new NotFoundException("Métier introuvable"));
    }
}
