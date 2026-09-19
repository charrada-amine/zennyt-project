package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.PushPlatform;
import jakarta.persistence.*;
import org.hibernate.Length;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "push_devices", schema = "engagement",
    uniqueConstraints = @UniqueConstraint(name = "push_devices_token_key", columnNames = {"token"}),
    indexes = @Index(name = "idx_engagement_push_devices_user", columnList = "user_id"))
class PushDeviceEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID userId;
    @Column(nullable = false, length = Length.LONG32) private String token;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private PushPlatform platform;
    private String deviceName;
    @Column(nullable = false) private Instant updatedAt;

    protected PushDeviceEntity() {}

    PushDeviceEntity(UUID id, UUID userId, String token, PushPlatform platform,
                     String deviceName, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.token = token;
        this.platform = platform;
        this.deviceName = deviceName;
        this.updatedAt = updatedAt;
    }

    UUID getId() { return id; }
    UUID getUserId() { return userId; }
    String getToken() { return token; }
    PushPlatform getPlatform() { return platform; }
    String getDeviceName() { return deviceName; }
}
