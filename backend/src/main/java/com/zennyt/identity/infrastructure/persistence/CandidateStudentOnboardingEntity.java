package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Entity
@Table(name = "candidate_student_onboarding_infos", uniqueConstraints =
    @UniqueConstraint(name = "candidate_student_onboarding_infos_user_id_key", columnNames = {"user_id"}))
@Check(name = "ck_candidate_experience", constraints = "years_of_experience IS NULL OR years_of_experience >= 0")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CandidateStudentOnboardingEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "candidate_student_onboarding_infos_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;
    @Column(length = 150)
    private String school;
    @Column(name = "education_level", length = 150)
    private String educationLevel;
    @Column(name = "field_of_work", length = 150)
    private String fieldOfWork;
    @Column(name = "last_position_held", length = 150)
    private String lastPositionHeld;
    @Column(name = "years_of_experience")
    private Integer yearsOfExperience;
    @Column(name = "cv_file_url", length = 500)
    private String cvFileUrl;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public CandidateStudentOnboardingEntity(Long id, Long userId, String school, String educationLevel,
                                            String fieldOfWork, String lastPositionHeld,
                                            Integer yearsOfExperience, String cvFileUrl,
                                            Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.school = school;
        this.educationLevel = educationLevel;
        this.fieldOfWork = fieldOfWork;
        this.lastPositionHeld = lastPositionHeld;
        this.yearsOfExperience = yearsOfExperience;
        this.cvFileUrl = cvFileUrl;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
