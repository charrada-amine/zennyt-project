package com.zennyt.recruitment.infrastructure.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.domain.model.PresentedQuestion;
import com.zennyt.recruitment.domain.model.TestAttempt;
import com.zennyt.recruitment.domain.repository.TestAttemptRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class TestAttemptRepositoryAdapter implements TestAttemptRepository {
    private final JpaTestAttemptRepository jpa;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public TestAttemptRepositoryAdapter(JpaTestAttemptRepository jpa) { this.jpa = jpa; }

    @Override public TestAttempt save(TestAttempt a) { return toDomain(jpa.save(toEntity(a))); }
    @Override public Optional<TestAttempt> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    private TestAttemptEntity toEntity(TestAttempt a) {
        String json;
        try { json = objectMapper.writeValueAsString(a.presentedQuestions()); }
        catch (JsonProcessingException ex) { json = "[]"; }
        return new TestAttemptEntity(a.id(), a.jobOfferId(), a.hardSkillTestId(), a.candidateId(),
            a.startedAt(), a.expiresAt(), json, a.status());
    }

    private TestAttempt toDomain(TestAttemptEntity e) {
        List<PresentedQuestion> presented;
        try { presented = objectMapper.readValue(e.getPresentedQuestionsJson(), new TypeReference<>() {}); }
        catch (Exception ex) { presented = List.of(); }
        return TestAttempt.rehydrate(e.getId(), e.getJobOfferId(), e.getHardSkillTestId(), e.getCandidateId(),
            e.getStartedAt(), e.getExpiresAt(), presented, e.getStatus());
    }
}
