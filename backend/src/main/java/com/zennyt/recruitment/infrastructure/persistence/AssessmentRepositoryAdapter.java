package com.zennyt.recruitment.infrastructure.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class AssessmentRepositoryAdapter implements AssessmentRepository {
    private final JpaAssessmentRepository jpa;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AssessmentRepositoryAdapter(JpaAssessmentRepository jpa) { this.jpa = jpa; }

    @Override public Assessment save(Assessment a) { return toDomain(jpa.save(toEntity(a))); }
    @Override public Optional<Assessment> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }
    @Override public void deleteById(UUID id) { jpa.deleteById(id); }

    @Override public List<Assessment> findByRecruiterId(UUID recruiterId, int page, int size) {
        return jpa.findByCreatedByRecruiterId(recruiterId, PageRequest.of(page, size)).map(this::toDomain).getContent();
    }
    @Override public long countByRecruiterId(UUID recruiterId) { return jpa.countByCreatedByRecruiterId(recruiterId); }
    @Override public List<Assessment> findByIdIn(List<UUID> ids) { return jpa.findByIdIn(ids).stream().map(this::toDomain).toList(); }

    private AssessmentEntity toEntity(Assessment a) {
        AssessmentEntity e = new AssessmentEntity();
        e.setId(a.id()); e.setCreatedByRecruiterId(a.createdByRecruiterId());
        e.setTitle(a.title()); e.setTimeLimitSeconds(a.timeLimitSeconds());
        e.setMaxQuestions(a.maxQuestions()); e.setGenerationSource(a.generationSource());
        e.setShareableLink(a.shareableLink()); e.setCreatedAt(a.createdAt());
        try { e.setQuestionsJson(objectMapper.writeValueAsString(a.questions())); }
        catch (JsonProcessingException ex) { e.setQuestionsJson("[]"); }
        return e;
    }

    private Assessment toDomain(AssessmentEntity e) {
        List<AssessmentQuestion> questions;
        try { questions = objectMapper.readValue(e.getQuestionsJson(), new TypeReference<>() {}); }
        catch (Exception ex) { questions = List.of(); }
        return Assessment.rehydrate(e.getId(), e.getCreatedByRecruiterId(), e.getTitle(),
            e.getTimeLimitSeconds(), e.getMaxQuestions(), e.getGenerationSource(),
            e.getShareableLink(), questions, e.getCreatedAt());
    }
}
