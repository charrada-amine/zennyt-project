package com.zennyt.recruitment.infrastructure.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.domain.model.TestAnswer;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Component
public class TestResultRepositoryAdapter implements TestResultRepository {
    private static final Set<String> SORTABLE_FIELDS = Set.of("completedAt", "percentage", "score");
    private static final Sort DEFAULT_SORT = Sort.by("completedAt").descending();

    private final JpaTestResultRepository jpa;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public TestResultRepositoryAdapter(JpaTestResultRepository jpa) { this.jpa = jpa; }

    @Override public TestResult save(TestResult r) { return toDomain(jpa.save(toEntity(r))); }
    @Override public Optional<TestResult> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    @Override public Optional<TestResult> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.findFirstByCandidateIdAndJobOfferId(candidateId, jobOfferId).map(this::toDomain);
    }

    @Override public List<TestResult> findByCandidateIdsAndJobOfferIds(List<UUID> candidateIds,
                                                                      List<UUID> jobOfferIds) {
        if (candidateIds.isEmpty() || jobOfferIds.isEmpty()) return List.of();
        return jpa.findByCandidateIdInAndJobOfferIdIn(candidateIds, jobOfferIds).stream()
            .map(this::toDomain).toList();
    }

    @Override public boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.existsByCandidateIdAndJobOfferId(candidateId, jobOfferId);
    }

    @Override public List<TestResult> findByJobOfferId(UUID jobOfferId, String sort, int page, int size) {
        var pageable = PageRequest.of(page, size, SortParam.parse(sort, SORTABLE_FIELDS, DEFAULT_SORT));
        return jpa.findByJobOfferId(jobOfferId, pageable).map(this::toDomain).getContent();
    }

    @Override public long countByJobOfferId(UUID jobOfferId) { return jpa.countByJobOfferId(jobOfferId); }

    @Override public List<TestResult> findAllByJobOfferId(UUID jobOfferId) {
        return jpa.findAllByJobOfferId(jobOfferId).stream().map(this::toDomain).toList();
    }

    private TestResultEntity toEntity(TestResult r) {
        String json;
        try { json = objectMapper.writeValueAsString(r.answers()); }
        catch (JsonProcessingException ex) { json = "[]"; }
        return new TestResultEntity(r.id(), r.jobOfferId(), r.hardSkillTestId(), r.candidateId(),
            r.score(), r.percentage(), r.passed(), json, r.startedAt(), r.completedAt(),
            r.duration(), r.status());
    }

    private TestResult toDomain(TestResultEntity e) {
        List<TestAnswer> answers;
        try { answers = objectMapper.readValue(e.getAnswersJson(), new TypeReference<>() {}); }
        catch (Exception ex) { answers = List.of(); }
        return TestResult.rehydrate(e.getId(), e.getJobOfferId(), e.getHardSkillTestId(), e.getCandidateId(),
            e.getScore(), e.getPercentage(), e.isPassed(), answers,
            e.getStartedAt(), e.getCompletedAt(), e.getDuration(), e.getStatus());
    }
}
