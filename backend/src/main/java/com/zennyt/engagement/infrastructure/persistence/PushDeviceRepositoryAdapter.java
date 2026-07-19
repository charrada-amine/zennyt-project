package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.PushDevice;
import com.zennyt.engagement.domain.repository.PushDeviceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class PushDeviceRepositoryAdapter implements PushDeviceRepository {
    private final JpaPushDeviceRepository jpa;

    @Override
    public PushDevice save(PushDevice device) {
        return toDomain(jpa.save(new PushDeviceEntity(
            device.id(), device.userId(), device.token(), device.platform(),
            device.deviceName(), Instant.now())));
    }

    @Override
    public Optional<PushDevice> findByToken(String token) {
        return jpa.findByToken(token).map(this::toDomain);
    }

    private PushDevice toDomain(PushDeviceEntity entity) {
        return PushDevice.rehydrate(entity.getId(), entity.getUserId(), entity.getToken(),
            entity.getPlatform(), entity.getDeviceName());
    }
}
