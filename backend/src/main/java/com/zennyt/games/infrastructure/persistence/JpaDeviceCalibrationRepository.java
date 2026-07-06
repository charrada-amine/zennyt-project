package com.zennyt.games.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/** Spring Data JPA pour {@link DeviceCalibrationEntity}. */
public interface JpaDeviceCalibrationRepository
    extends JpaRepository<DeviceCalibrationEntity, UUID> {
}
