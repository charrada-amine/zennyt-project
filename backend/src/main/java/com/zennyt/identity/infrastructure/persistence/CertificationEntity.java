package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.Certification;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "certifications")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CertificationEntity {
    @Getter(AccessLevel.PACKAGE)
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profile_id", nullable = false)
    private ProfileEntity profile;
    @Column(nullable = false, length = 150)
    private String title;
    @Column(length = 150)
    private String issuer;
    @Column(name = "completion_date")
    private LocalDate completionDate;
    @Column(name = "credential_id", length = 150)
    private String credentialId;
    @Column(name = "credential_url", length = 500)
    private String credentialUrl;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    CertificationEntity(ProfileEntity profile, Certification value) {
        this.profile = profile;
        this.createdAt = value.createdAt();
        updateFrom(value);
    }

    void updateFrom(Certification value) {
        this.title = value.title();
        this.issuer = value.issuer(); this.completionDate = value.completionDate();
        this.credentialId = value.credentialId(); this.credentialUrl = value.credentialUrl();
        this.updatedAt = value.updatedAt();
    }

    Certification toDomain() {
        return new Certification(id, title, issuer, completionDate, credentialId, credentialUrl,
            createdAt, updatedAt);
    }
}
