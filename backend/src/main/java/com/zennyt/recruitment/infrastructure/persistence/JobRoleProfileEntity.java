package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "job_role_profiles", schema = "recruitment")
public class JobRoleProfileEntity {
    @Id private UUID id;
    @Enumerated(EnumType.STRING) @Column(name = "profile_type", nullable = false) private JobProfileType profileType;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private ExperienceLevel level;
    @Column(name = "soft_weight", nullable = false) private int softWeight;
    @Column(name = "hard_weight", nullable = false) private int hardWeight;
    @Column(name = "expected_hard_weight", nullable = false) private int expectedHardWeight;
    @Column(name = "cognitive_flexibility_weight", nullable = false) private int cognitiveFlexibilityWeight;
    @Column(name = "working_memory_weight", nullable = false) private int workingMemoryWeight;
    @Column(name = "decision_making_weight", nullable = false) private int decisionMakingWeight;
    @Column(name = "executive_planning_weight", nullable = false) private int executivePlanningWeight;
    @Column(name = "emotional_regulation_weight", nullable = false) private int emotionalRegulationWeight;
    @Enumerated(EnumType.STRING) @Column(name = "type_evaluation_hard", nullable = false)
    private TypeEvaluationHard typeEvaluationHard;
    @Column(nullable = false) private boolean calibrated;
    /** F11 — horodatage du referentiel, prerequis du balayage de peremption (F12). */
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    protected JobRoleProfileEntity() {}

    public JobRoleProfileEntity(UUID id, JobProfileType profileType, ExperienceLevel level,
                                int softWeight, int hardWeight, int expectedHardWeight,
                                int cognitiveFlexibilityWeight, int workingMemoryWeight,
                                int decisionMakingWeight, int executivePlanningWeight,
                                int emotionalRegulationWeight, TypeEvaluationHard typeEvaluationHard,
                                boolean calibrated, Instant updatedAt) {
        this.id = id;
        this.profileType = profileType;
        this.level = level;
        this.softWeight = softWeight;
        this.hardWeight = hardWeight;
        this.expectedHardWeight = expectedHardWeight;
        this.cognitiveFlexibilityWeight = cognitiveFlexibilityWeight;
        this.workingMemoryWeight = workingMemoryWeight;
        this.decisionMakingWeight = decisionMakingWeight;
        this.executivePlanningWeight = executivePlanningWeight;
        this.emotionalRegulationWeight = emotionalRegulationWeight;
        this.typeEvaluationHard = typeEvaluationHard;
        this.calibrated = calibrated;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public JobProfileType getProfileType() { return profileType; }
    public ExperienceLevel getLevel() { return level; }
    public int getSoftWeight() { return softWeight; }
    public int getHardWeight() { return hardWeight; }
    public int getExpectedHardWeight() { return expectedHardWeight; }
    public int getCognitiveFlexibilityWeight() { return cognitiveFlexibilityWeight; }
    public int getWorkingMemoryWeight() { return workingMemoryWeight; }
    public int getDecisionMakingWeight() { return decisionMakingWeight; }
    public int getExecutivePlanningWeight() { return executivePlanningWeight; }
    public int getEmotionalRegulationWeight() { return emotionalRegulationWeight; }
    public TypeEvaluationHard getTypeEvaluationHard() { return typeEvaluationHard; }
    public boolean isCalibrated() { return calibrated; }
    public Instant getUpdatedAt() { return updatedAt; }
}
