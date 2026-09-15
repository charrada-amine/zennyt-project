package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Cas d'usage : recherche générale de candidats (recruteur), hors offre. */
@Service
@RequiredArgsConstructor
public class SearchCandidatesUseCase {

    private final RecruitmentActorRepository actors;

    @Transactional(readOnly = true)
    public List<RecruitmentActor> execute(String query, String location, int page, int size) {
        return actors.searchCandidates(query, location, page, size);
    }
}
