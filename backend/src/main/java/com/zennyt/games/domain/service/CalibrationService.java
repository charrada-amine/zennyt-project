package com.zennyt.games.domain.service;

import com.zennyt.games.domain.vo.DeviceCalibration;

/**
 * Service de domaine transversal : applique le calibrage APPAREIL aux temps bruts.
 *
 * <p>Java pur, sans Spring. C'est le point unique où la correction technique
 * (latence machine) est retranchée du temps mesuré pour obtenir un temps de
 * réaction <b>cognitif</b>. Conçu pour être trivialement réutilisable :
 * <ul>
 *   <li>Move Fast — corrige les <i>indicateurs comportementaux</i> (le score ne
 *       dépend pas du temps) ;</li>
 *   <li>Decision/DT, Memory Quest/timeout — corrigera les temps <i>avant scoring</i>
 *       quand un score dépendra du temps.</li>
 * </ul>
 * Les essais d'échauffement ne servent jamais au calibrage : l'offset est purement
 * technique (niveau appareil), indépendant des essais.
 */
public class CalibrationService {

    /** Offset à retrancher des temps bruts ; 0 si aucun calibrage fourni. */
    public double offsetMs(DeviceCalibration calibration) {
        return calibration == null ? 0.0 : calibration.calibrationOffsetMs();
    }

    /** Temps de réaction cognitif = temps brut − offset (plancher 0). */
    public double adjust(double rawMs, double offsetMs) {
        return Math.max(0.0, rawMs - offsetMs);
    }

    /** Raccourci : corrige un temps brut directement à partir du calibrage. */
    public double adjust(double rawMs, DeviceCalibration calibration) {
        return adjust(rawMs, offsetMs(calibration));
    }
}
