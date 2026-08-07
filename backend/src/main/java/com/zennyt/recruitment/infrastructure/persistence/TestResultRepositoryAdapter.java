package com.zennyt.recruitment.infrastructure.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.domain.model.TestAnswer;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.CandidateJobPositionCouple;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
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

    @Override public List<TestResult> findByPairs(List<CandidateOfferPair> pairs) {
        if (pairs.isEmpty()) return List.of();
        return jpa.findByPairs(PairArrays.candidateIds(pairs), PairArrays.jobOfferIds(pairs)).stream()
            .map(this::toDomain).toList();
    }

    @Override public boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.existsByCandidateIdAndJobOfferId(candidateId, jobOfferId);
    }

    @Override public List<HardSkillHistoryEntry> findHardSkillHistory(UUID candidateId, UUID jobPositionId) {
        if (candidateId == null || jobPositionId == null) return List.of();
        return jpa.findHardSkillHistory(candidateId, jobPositionId).stream()
            .map(TestResultRepositoryAdapter::toHistoryEntry).toList();
    }

    @Override public List<HardSkillHistoryEntry> findHardSkillHistoryByCouples(
            List<CandidateJobPositionCouple> couples) {
        if (couples.isEmpty()) return List.of();
        return jpa.findHardSkillHistoryByCouples(
                PairArrays.coupleCandidateIds(couples), PairArrays.coupleJobPositionIds(couples)).stream()
            .map(TestResultRepositoryAdapter::toHistoryEntry).toList();
    }

    /** Projection native — les colonnes arrivent dans l'ordre du SELECT, pas par nom. */
    private static HardSkillHistoryEntry toHistoryEntry(Object[] row) {
        return new HardSkillHistoryEntry(
            (UUID) row[0], (UUID) row[1], (UUID) row[2],
            ((Number) row[3]).intValue(), (Boolean) row[4],
            toInstant(row[5]),
            (String) row[6]);
    }

    /**
     * Le type Java d'une colonne {@code timestamptz} lue en requête native n'est pas
     * garanti : selon la version du pilote et la configuration, elle remonte en
     * {@link Instant}, en {@link java.sql.Timestamp} ou en {@link OffsetDateTime}. Un cast
     * direct compile sans broncher puis échoue à l'exécution — d'où ce point de conversion
     * unique.
     */
    private static Instant toInstant(Object value) {
        if (value instanceof Instant instant) return instant;
        if (value instanceof java.sql.Timestamp timestamp) return timestamp.toInstant();
        if (value instanceof OffsetDateTime offsetDateTime) return offsetDateTime.toInstant();
        throw new IllegalStateException(
            "Type d'horodatage inattendu : " + value.getClass().getName());
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
