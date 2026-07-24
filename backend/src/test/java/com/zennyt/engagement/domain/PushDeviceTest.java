package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.PushDevice;
import com.zennyt.engagement.domain.vo.PushPlatform;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/** Tests de caractérisation de PushDevice, sans Spring ni persistance. */
class PushDeviceTest {

    @Test
    void register_generates_identity_and_preserves_registration_data() {
        UUID userId = UUID.randomUUID();

        PushDevice device = PushDevice.register(userId, "push-token", PushPlatform.ANDROID, "Pixel");

        assertNotNull(device.id());
        assertEquals(userId, device.userId());
        assertEquals("push-token", device.token());
        assertEquals(PushPlatform.ANDROID, device.platform());
        assertEquals("Pixel", device.deviceName());
    }

    @Test
    void rehydrate_preserves_all_fields() {
        UUID id = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        PushDevice device = PushDevice.rehydrate(id, userId, "ios-token", PushPlatform.IOS, null);

        assertEquals(id, device.id());
        assertEquals(userId, device.userId());
        assertEquals("ios-token", device.token());
        assertEquals(PushPlatform.IOS, device.platform());
        assertNull(device.deviceName());
    }

    @Test
    void registration_requires_a_token_and_platform() {
        UUID userId = UUID.randomUUID();

        assertThrows(IllegalArgumentException.class,
            () -> PushDevice.register(userId, " ", PushPlatform.IOS, null));
        assertThrows(NullPointerException.class,
            () -> PushDevice.register(userId, "token", null, null));
    }

    @Test
    void refresh_updates_only_a_device_owned_by_the_same_user() {
        UUID ownerId = UUID.randomUUID();
        PushDevice device = PushDevice.register(ownerId, "token", PushPlatform.IOS, null);

        PushDevice refreshed = device.refresh(ownerId, PushPlatform.ANDROID, "Pixel");

        assertEquals(PushPlatform.ANDROID, refreshed.platform());
        assertEquals("Pixel", refreshed.deviceName());
        assertThrows(IllegalArgumentException.class,
            () -> device.refresh(UUID.randomUUID(), PushPlatform.IOS, "iPhone"));
    }
}
