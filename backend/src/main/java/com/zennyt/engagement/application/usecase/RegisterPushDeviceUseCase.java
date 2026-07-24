package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.PushDevice;
import com.zennyt.engagement.domain.repository.PushDeviceRepository;
import com.zennyt.engagement.domain.vo.PushPlatform;
import com.zennyt.shared.application.exception.ConflictException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RegisterPushDeviceUseCase {
    private final PushDeviceRepository devices;

    @Transactional
    public PushDevice execute(UUID actorId, String token,
                              PushPlatform platform, String deviceName) {
        PushDevice device = devices.findByToken(token).map(existing -> {
            if (!existing.userId().equals(actorId)) {
                throw new ConflictException("Ce token push appartient déjà à un autre utilisateur");
            }
            return existing.refresh(actorId, platform, deviceName);
        }).orElseGet(() -> PushDevice.register(actorId, token, platform, deviceName));
        return devices.save(device);
    }
}
