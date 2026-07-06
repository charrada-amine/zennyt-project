package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.vo.DeviceCalibration;
import org.springframework.stereotype.Component;

/**
 * Adaptateur de persistance du calibrage appareil : mappe le VO domaine
 * {@link DeviceCalibration} vers {@link DeviceCalibrationEntity}. Upsert par
 * {@code sessionId} (l'entité a la session pour identifiant).
 */
@Component
public class DeviceCalibrationRepositoryAdapter implements DeviceCalibrationRepository {

    private final JpaDeviceCalibrationRepository jpa;

    public DeviceCalibrationRepositoryAdapter(JpaDeviceCalibrationRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public void save(DeviceCalibration c) {
        jpa.save(new DeviceCalibrationEntity(
            c.sessionId(), c.calibrationMethod().wire(), c.inputMode(), c.deviceCategory(),
            c.refreshRateHz(), c.hardwareConcurrency(), c.deviceMemoryGb(),
            c.inputProcessingLatencyMs(), c.displayLatencyMs(), c.calibrationOffsetMs(),
            c.reducedReliability()));
    }
}
