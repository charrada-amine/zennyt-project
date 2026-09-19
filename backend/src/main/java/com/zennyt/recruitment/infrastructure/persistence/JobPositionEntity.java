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
import jakarta.persistence.Index;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
// Index unique partiel uq_job_positions_name_no_sector (métiers transverses) : db/schema-complements.sql.
@Table(name = "job_positions", schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(name = "uq_job_positions_name_sector", columnNames = {"name", "sector"}),
    indexes = @Index(name = "ix_job_positions_status", columnList = "status"))
@Check(name = "ck_job_positions_type_evaluation_hard", constraints = "type_evaluation_hard IN ('QCM', 'PORTFOLIO', 'MIXTE')")
public class JobPositionEntity {
    @Id private UUID id;
    @Column(nullable = false, length = 150) private String name;
    @Column(length = 100) private String sector;
    @Enumerated(EnumType.STRING) @Column(length = 20) private JobProfileType profileType;
    /** F32 — mode de mesure du hard skills, propre au métier (décision D-C, V60). */
    @ColumnDefault("'QCM'")
    @Enumerated(EnumType.STRING) @Column(name = "type_evaluation_hard", nullable = false, length = 20)
    private TypeEvaluationHard typeEvaluationHard = TypeEvaluationHard.QCM;
    @ColumnDefault("false") @Column(nullable = false) private boolean calibrated;
    @ColumnDefault("'PENDING_APPROVAL'")
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private JobPositionStatus status;
    private UUID proposedByRecruiterId;
    @Column(length = 100) private String juniorLabel;
    @Column(length = 100) private String seniorLabel;
    @Column(length = 100) private String leadLabel;
    @Column(length = 100) private String managerLabel;
    @Column(nullable = false) private Instant createdAt;
    @Column(length = Length.LONG32) private String embedding;
    @Enumerated(EnumType.STRING) @Column(length = 20) private JobProfileType suggestedProfileType;

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
