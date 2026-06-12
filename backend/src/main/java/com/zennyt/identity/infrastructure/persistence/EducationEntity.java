package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.Education;
import jakarta.persistence.*;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "education")
public class EducationEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profile_id", nullable = false)
    private ProfileEntity profile;
    @Column(nullable = false, length = 150)
    private String degree;
    @Column(length = 150)
    private String school;
    @Column(name = "field_of_study", length = 150)
    private String fieldOfStudy;
    @Column(columnDefinition = "TEXT")
    private String description;
    @Column(name = "start_date")
    private LocalDate startDate;
    @Column(name = "end_date")
    private LocalDate endDate;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected EducationEntity() {}
    EducationEntity(ProfileEntity profile, Education value) {
        this.profile = profile;
        this.createdAt = value.createdAt();
        updateFrom(value);
    }
    Long getId() { return id; }
    void updateFrom(Education value) {
        this.degree = value.degree();
        this.school = value.school(); this.fieldOfStudy = value.fieldOfStudy();
        this.description = value.description(); this.startDate = value.startDate();
        this.endDate = value.endDate(); this.updatedAt = value.updatedAt();
    }
    Education toDomain() {
        return new Education(id, degree, school, fieldOfStudy, description, startDate, endDate,
            createdAt, updatedAt);
    }
}
