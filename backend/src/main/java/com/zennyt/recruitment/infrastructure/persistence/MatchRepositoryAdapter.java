package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class MatchRepositoryAdapter implements MatchRepository {
    private final JpaMatchRepository jpa;
    public MatchRepositoryAdapter(JpaMatchRepository jpa) { this.jpa = jpa; }

    @Override public Match save(Match m) { return toDomain(jpa.save(toEntity(m))); }
    @Override public Optional<Match> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }
    @Override public Optional<Match> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.findFirstByCandidateIdAndJobOfferId(candidateId, jobOfferId).map(this::toDomain);
    }
    @Override public void deleteById(UUID id) { jpa.deleteById(id); }

    @Override public List<Match> findByCandidateId(UUID candidateId, int page, int size) {
        return jpa.findByCandidateId(candidateId, PageRequest.of(page, size)).map(this::toDomain).getContent();
    }
    @Override public long countByCandidateId(UUID candidateId) { return jpa.countByCandidateId(candidateId); }

    @Override public List<Match> findByJobOfferId(UUID jobOfferId, int page, int size) {
        return jpa.findByJobOfferId(jobOfferId, PageRequest.of(page, size)).map(this::toDomain).getContent();
    }
    @Override public long countByJobOfferId(UUID jobOfferId) { return jpa.countByJobOfferId(jobOfferId); }

    private MatchEntity toEntity(Match m) { return new MatchEntity(m.id(), m.candidateId(), m.jobOfferId(), m.recruiterId(), m.matchedAt()); }
    private Match toDomain(MatchEntity e) { return Match.rehydrate(e.getId(), e.getCandidateId(), e.getJobOfferId(), e.getRecruiterId(), e.getMatchedAt()); }
}
