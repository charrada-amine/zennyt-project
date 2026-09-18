package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.SearchCandidatesUseCase;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.WorkplaceType;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Recherche générale de candidats (maquette 87-89, onglet recruteur), sans offre
 * active : filtre par nom et localisation sur la projection acteurs.
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class CandidateSearchController {

    private final SearchCandidatesUseCase searchCandidates;

    record CandidateSearchResult(UUID id, String fullName, String avatarUrl, String city,
                                 String country, String lookingFor, Integer yearsOfExperience,
                                 WorkplaceType workplaceTypePreference,
                                 ContractType contractTypePreference, String targetLocation,
                                 boolean openInternationally) {
        static CandidateSearchResult from(RecruitmentActor actor) {
            return new CandidateSearchResult(actor.publicUserId(), actor.fullName(),
                actor.avatarUrl(), actor.city(), actor.country(), actor.lookingFor(),
                actor.yearsOfExperience(), actor.workplaceTypePreference(),
                actor.contractTypePreference(), actor.targetLocation(),
                Boolean.TRUE.equals(actor.openInternationally()));
        }
    }

    @GetMapping("/candidates/search")
    @RecruiterOnly
    public List<CandidateSearchResult> search(@RequestParam(required = false) String q,
                                              @RequestParam(required = false) String location,
                                              @RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "20") int size) {
        return searchCandidates.execute(q, location, page, size).stream()
            .map(CandidateSearchResult::from)
            .toList();
    }
}
