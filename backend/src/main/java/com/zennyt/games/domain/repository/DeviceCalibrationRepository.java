package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.DeviceCalibration;

/**
 * Port de persistance du calibrage appareil. Le domaine ignore JPA.
 *
 * <p>Une session porte au plus un calibrage : {@link #save(DeviceCalibration)}
 * fait un upsert par {@code sessionId}.
 */
public interface DeviceCalibrationRepository {
    void save(DeviceCalibration calibration);
}
