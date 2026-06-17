package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.Position;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "positions")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PositionEntity {
    @Getter(AccessLevel.PACKAGE)
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profile_id", nullable = false)
    private ProfileEntity profile;
    @Column(nullable = false, length = 150)
    private String title;
    @Column(name = "company_name", length = 150)
    private String companyName;
    @Column(length = 150)
    private String location;
    @Column(columnDefinition = "TEXT")
    private String description;
    @Column(name = "start_date")
    private LocalDate startDate;
    @Column(name = "end_date")
    private LocalDate endDate;
    @Column(name = "is_current", nullable = false)
    private boolean current;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    PositionEntity(ProfileEntity profile, Position value) {
        this.profile = profile;
        this.createdAt = value.createdAt();
        updateFrom(value);
    }

    void updateFrom(Position value) {
        this.title = value.title();
        this.companyName = value.companyName(); this.location = value.location();
        this.description = value.description(); this.startDate = value.startDate();
        this.endDate = value.endDate(); this.current = value.current();
        this.updatedAt = value.updatedAt();
    }

    Position toDomain() {
        return new Position(id, title, companyName, location, description, startDate, endDate,
            current, createdAt, updatedAt);
    }
}
