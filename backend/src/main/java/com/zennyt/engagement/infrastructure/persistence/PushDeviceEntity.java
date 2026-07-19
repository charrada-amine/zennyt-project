package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.PushPlatform;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "push_devices", schema = "engagement")
class PushDeviceEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID userId;
    @Column(nullable = false, unique = true, columnDefinition = "TEXT") private String token;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private PushPlatform platform;
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
