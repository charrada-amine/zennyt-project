package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.DeviceCategory;
import com.zennyt.games.domain.vo.InputMode;
import jakarta.persistence.*;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.util.UUID;

/**
 * Entité JPA du calibrage appareil (table {@code games.device_calibrations}).
 *
 * <p>Les temps BRUTS restent stockés côté métriques ; cette table conserve le
 * profil de calibrage et l'offset calculé pour audit/reproductibilité. Clé sur
 * {@code sessionId} (au plus un calibrage par session).
 */
@Entity
@Table(name = "device_calibrations", schema = "games")
@Check(name = "ck_device_calibrations_category", constraints = "device_category IN ('MOBILE', 'TABLET', 'DESKTOP')")
@Check(name = "ck_device_calibrations_input_mode", constraints = "input_mode IN ('KEYBOARD', 'TOUCH', 'MOUSE', 'SWIPE')")
@Check(name = "ck_device_calibrations_method", constraints = "calibration_method IN ('technique', 'hardware_profile_fallback')")
@Check(name = "ck_device_calibrations_refresh", constraints = "refresh_rate_hz > 0")
public class DeviceCalibrationEntity {

    @Id
    @Column(name = "session_id")
    private UUID sessionId;

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "device_calibrations_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    @Column(name = "calibration_method", nullable = false, length = 40)
    private String calibrationMethod;

    @Enumerated(EnumType.STRING)
    @Column(name = "input_mode", nullable = false, length = 20)
    private InputMode inputMode;

    @Enumerated(EnumType.STRING)
    @Column(name = "device_category", nullable = false, length = 20)
    private DeviceCategory deviceCategory;

    @Column(name = "refresh_rate_hz", nullable = false)
    private double refreshRateHz;

    @Column(name = "hardware_concurrency")
    private Integer hardwareConcurrency;

    @Column(name = "device_memory_gb")
    private Double deviceMemoryGb;

    @Column(name = "input_processing_latency_ms")
    private Double inputProcessingLatencyMs;

    @Column(name = "display_latency_ms", nullable = false)
    private double displayLatencyMs;

    @Column(name = "calibration_offset_ms", nullable = false)
    private double calibrationOffsetMs;

    @Column(name = "reduced_reliability", nullable = false)
    private boolean reducedReliability;

    protected DeviceCalibrationEntity() { } // requis par JPA

    public DeviceCalibrationEntity(UUID sessionId, String calibrationMethod, InputMode inputMode,
                                   DeviceCategory deviceCategory, double refreshRateHz,
                                   Integer hardwareConcurrency, Double deviceMemoryGb,
                                   Double inputProcessingLatencyMs, double displayLatencyMs,
                                   double calibrationOffsetMs, boolean reducedReliability) {
        this.sessionId = sessionId;
        this.calibrationMethod = calibrationMethod;
        this.inputMode = inputMode;
        this.deviceCategory = deviceCategory;
        this.refreshRateHz = refreshRateHz;
        this.hardwareConcurrency = hardwareConcurrency;
        this.deviceMemoryGb = deviceMemoryGb;
        this.inputProcessingLatencyMs = inputProcessingLatencyMs;
        this.displayLatencyMs = displayLatencyMs;
        this.calibrationOffsetMs = calibrationOffsetMs;
        this.reducedReliability = reducedReliability;
    }

    public UUID getSessionId() { return sessionId; }
}
