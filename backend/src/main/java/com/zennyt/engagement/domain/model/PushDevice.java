package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.PushPlatform;

import java.util.Objects;
import java.util.UUID;

/** Appareil enregistré pour les notifications push. */
public class PushDevice {

    private final UUID id;
    private final UUID userId;
    private final String token;
    private final PushPlatform platform;
    private final String deviceName;

    private PushDevice(UUID id, UUID userId, String token,
                       PushPlatform platform, String deviceName) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Le token push est obligatoire");
        }
        this.token = token;
        this.platform = Objects.requireNonNull(platform, "platform");
        this.deviceName = deviceName;
    }

    public static PushDevice register(UUID userId, String token,
                                      PushPlatform platform, String deviceName) {
        return new PushDevice(UUID.randomUUID(), userId, token, platform, deviceName);
    }

    public static PushDevice rehydrate(UUID id, UUID userId, String token,
                                       PushPlatform platform, String deviceName) {
        return new PushDevice(id, userId, token, platform, deviceName);
    }

    public PushDevice refresh(UUID requestingUserId, PushPlatform newPlatform, String newDeviceName) {
        if (!userId.equals(requestingUserId)) {
            throw new IllegalArgumentException("Ce token appartient à un autre utilisateur");
        }
        return new PushDevice(id, userId, token, newPlatform, newDeviceName);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String token() { return token; }
    public PushPlatform platform() { return platform; }
    public String deviceName() { return deviceName; }
}
