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

    private static final int MIN_PAGE = 0;
    private static final int MIN_SIZE = 1;
    private static final int MAX_SIZE = 100;

    private final RecruitmentActorRepository actors;

    @Transactional(readOnly = true)
    public List<RecruitmentActor> execute(String query, String location, int page, int size) {
        return actors.searchCandidates(query, location, Math.max(MIN_PAGE, page),
            Math.clamp(size, MIN_SIZE, MAX_SIZE));
    }
}
