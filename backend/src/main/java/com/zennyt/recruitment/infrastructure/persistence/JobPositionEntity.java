package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.JobPositionStatus;
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
@Table(name = "job_positions", schema = "recruitment")
public class JobPositionEntity {
    @Id private UUID id;
    @Column(nullable = false) private String name;
    private String sector;
    @Enumerated(EnumType.STRING) private JobProfileType profileType;
    /** F32 — mode de mesure du hard skills, propre au métier (décision D-C, V60). */
    @Enumerated(EnumType.STRING) @Column(name = "type_evaluation_hard", nullable = false)
    private TypeEvaluationHard typeEvaluationHard = TypeEvaluationHard.QCM;
    @Column(nullable = false) private boolean calibrated;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private JobPositionStatus status;
    private UUID proposedByRecruiterId;
    private String juniorLabel;
    private String seniorLabel;
    private String leadLabel;
    private String managerLabel;
    @Column(nullable = false) private Instant createdAt;
    @Column(columnDefinition = "TEXT") private String embedding;
    @Enumerated(EnumType.STRING) private JobProfileType suggestedProfileType;

    protected JobPositionEntity() {}

    JobPositionEntity(UUID id, String name, String sector, JobProfileType profileType,
                      TypeEvaluationHard typeEvaluationHard, boolean calibrated, JobPositionStatus status, UUID proposedByRecruiterId,
                      String juniorLabel, String seniorLabel, String leadLabel, String managerLabel,
                      Instant createdAt, String embedding, JobProfileType suggestedProfileType) {
        this.id = id;
        this.name = name;
        this.sector = sector;
        this.profileType = profileType;
        this.typeEvaluationHard = typeEvaluationHard != null ? typeEvaluationHard : TypeEvaluationHard.QCM;
        this.calibrated = calibrated;
        this.status = status;
        this.proposedByRecruiterId = proposedByRecruiterId;
        this.juniorLabel = juniorLabel;
        this.seniorLabel = seniorLabel;
        this.leadLabel = leadLabel;
        this.managerLabel = managerLabel;
        this.createdAt = createdAt;
        this.embedding = embedding;
        this.suggestedProfileType = suggestedProfileType;
    }

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getSector() { return sector; }
    public JobProfileType getProfileType() { return profileType; }
    public TypeEvaluationHard getTypeEvaluationHard() { return typeEvaluationHard; }
    public boolean isCalibrated() { return calibrated; }
    public JobPositionStatus getStatus() { return status; }
    public UUID getProposedByRecruiterId() { return proposedByRecruiterId; }
    public String getJuniorLabel() { return juniorLabel; }
    public String getSeniorLabel() { return seniorLabel; }
    public String getLeadLabel() { return leadLabel; }
    public String getManagerLabel() { return managerLabel; }
    public Instant getCreatedAt() { return createdAt; }
    public String getEmbedding() { return embedding; }
    public JobProfileType getSuggestedProfileType() { return suggestedProfileType; }
}
