package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.Skill;
import com.zennyt.identity.domain.model.SkillType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "skills")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SkillEntity {
    @Getter(AccessLevel.PACKAGE)
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profile_id", nullable = false)
    private ProfileEntity profile;
    @Column(nullable = false, length = 100)
    private String name;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private SkillType type;
    private Integer level;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    SkillEntity(ProfileEntity profile, Skill value) {
        this.profile = profile;
        this.createdAt = value.createdAt();
        updateFrom(value);
    }

    void updateFrom(Skill value) {
        this.name = value.name(); this.type = value.type(); this.level = value.level();
        this.updatedAt = value.updatedAt();
    }

    Skill toDomain() { return new Skill(id, name, type, level, createdAt, updatedAt); }
}
