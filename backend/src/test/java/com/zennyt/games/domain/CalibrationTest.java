package com.zennyt.games.domain;

import com.zennyt.games.domain.service.CalibrationService;
import com.zennyt.games.domain.vo.CalibrationMethod;
import com.zennyt.games.domain.vo.DeviceCalibration;
import com.zennyt.games.domain.vo.DeviceCategory;
import com.zennyt.games.domain.vo.InputMode;
import com.zennyt.games.domain.vo.MoveFastFlexibilityReport;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.MoveFastResponse;
import com.zennyt.games.domain.vo.MoveFastRule;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Socle de calibrage appareil (Tâche 4) — Java pur. */
class CalibrationTest {

    private final CalibrationService service = new CalibrationService();

    private static DeviceCalibration technique(double refreshHz, double inputLatency) {
        return new DeviceCalibration(
            UUID.randomUUID(), CalibrationMethod.TECHNIQUE, InputMode.TOUCH,
            DeviceCategory.MOBILE, refreshHz, 8, 4.0, inputLatency);
    }

    @Test
    void display_latency_and_offset_are_computed() {
        DeviceCalibration cal = technique(60.0, 12.0);
        // (1000/60)/2 = 8.333…
        assertEquals(8.3333, cal.displayLatencyMs(), 0.001);
        assertEquals(20.3333, cal.calibrationOffsetMs(), 0.001);
        assertFalse(cal.reducedReliability());
    }

    @Test
    void fallback_uses_display_component_only_and_is_reduced_reliability() {
        DeviceCalibration cal = new DeviceCalibration(
            UUID.randomUUID(), CalibrationMethod.HARDWARE_PROFILE_FALLBACK, InputMode.TOUCH,
            DeviceCategory.MOBILE, 120.0, null, null, null);
        // 120 Hz → display = (1000/120)/2 = 4.1667 ; pas de latence d'entrée
        assertEquals(4.1667, cal.calibrationOffsetMs(), 0.001);
        assertTrue(cal.reducedReliability());
    }

    @Test
    void technique_requires_input_processing_latency() {
        assertThrows(IllegalArgumentException.class, () -> new DeviceCalibration(
            UUID.randomUUID(), CalibrationMethod.TECHNIQUE, InputMode.TOUCH,
            DeviceCategory.MOBILE, 60.0, 8, 4.0, null));
    }

    @Test
    void service_adjusts_and_clamps_at_zero() {
        assertEquals(480.0, service.adjust(500.0, 20.0), 0.0001);
        assertEquals(0.0, service.adjust(10.0, 20.0), 0.0001);
        assertEquals(0.0, service.offsetMs(null), 0.0001); // pas de calibrage
    }

    @Test
    void move_fast_indicators_expose_adjusted_versions() {
        MoveFastMetrics metrics = new MoveFastMetrics(0, List.of(
            new MoveFastResponse(false, true, 500, MoveFastRule.ORIENTATION, false, false),
            new MoveFastResponse(false, true, 700, MoveFastRule.MOVEMENT, true, false)));
        double offset = 20.0;

        MoveFastFlexibilityReport report = MoveFastFlexibilityReport.from(
            metrics, 30, "completed", offset, true, true);

        assertEquals(600.0, report.averageReactionTimeMs(), 0.001);
        assertEquals(580.0, report.averageReactionTimeAdjustedMs(), 0.001); // 600 − 20
        assertTrue(report.calibrationApplied());
        assertTrue(report.calibrationReliable());
        // L'offset s'annule dans une différence : switchCost corrigé == brut
        assertEquals(report.switchCostMs(), report.switchCostAdjustedMs(), 0.001);
    }

    @Test
    void without_calibration_adjusted_equals_raw() {
        MoveFastMetrics metrics = new MoveFastMetrics(0, List.of(
            new MoveFastResponse(false, true, 400, MoveFastRule.ORIENTATION, false, false)));

        MoveFastFlexibilityReport report = MoveFastFlexibilityReport.from(metrics, 10, "completed");

        assertFalse(report.calibrationApplied());
        assertEquals(report.averageReactionTimeMs(), report.averageReactionTimeAdjustedMs(), 0.001);
        assertEquals(0.0, report.calibrationOffsetMs(), 0.001);
    }
}
