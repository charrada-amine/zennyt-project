package com.zennyt.games.domain.vo;

import java.util.UUID;

/**
 * Socle de calibrage APPAREIL — VO transversal (méthode « technique » pure).
 *
 * <p>Sépare la latence <b>machine</b> (affichage + traitement d'entrée) du temps
 * de réaction <b>cognitif</b> (fiche « JE BOUGE » Tableau 2 révisé + guide
 * Calibrage_Appareil). Les temps bruts sont conservés tels quels ; la correction
 * ({@link #calibrationOffsetMs()}) s'applique au moment du calcul des indicateurs.
 *
 * <p>Réutilisable par tout jeu dont un score ou un indicateur dépend du temps
 * (Move Fast aujourd'hui ; Decision/DT et Memory Quest/timeout demain).
 *
 * @param sessionId                session de rattachement (clé de liaison)
 * @param calibrationMethod        « technique » ou « hardware_profile_fallback »
 * @param inputMode                mode d'entrée
 * @param deviceCategory           catégorie d'appareil
 * @param refreshRateHz            taux de rafraîchissement détecté (> 0)
 * @param hardwareConcurrency      nombre de cœurs (détection passive, nullable)
 * @param deviceMemoryGb           mémoire en Go (détection passive, nullable — absent iOS)
 * @param inputProcessingLatencyMs médiane du traitement d'entrée sur la session
 *                                 (mesure machine ; nullable uniquement en fallback)
 */
public record DeviceCalibration(
    UUID sessionId,
    CalibrationMethod calibrationMethod,
    InputMode inputMode,
    DeviceCategory deviceCategory,
    double refreshRateHz,
    Integer hardwareConcurrency,
    Double deviceMemoryGb,
    Double inputProcessingLatencyMs
) {
    public DeviceCalibration {
        if (sessionId == null) {
            throw new IllegalArgumentException("sessionId est requis");
        }
        if (calibrationMethod == null || inputMode == null || deviceCategory == null) {
            throw new IllegalArgumentException("méthode, inputMode et deviceCategory sont requis");
        }
        if (refreshRateHz <= 0) {
            throw new IllegalArgumentException("refreshRateHz doit être > 0");
        }
        if (calibrationMethod == CalibrationMethod.TECHNIQUE
            && (inputProcessingLatencyMs == null || inputProcessingLatencyMs < 0)) {
            throw new IllegalArgumentException(
                "inputProcessingLatencyMs (>= 0) est requis pour la méthode technique");
        }
        if (inputProcessingLatencyMs != null && inputProcessingLatencyMs < 0) {
            throw new IllegalArgumentException("inputProcessingLatencyMs doit être >= 0");
        }
        if (hardwareConcurrency != null && hardwareConcurrency < 1) {
            throw new IllegalArgumentException("hardwareConcurrency doit être >= 1");
        }
        if (deviceMemoryGb != null && deviceMemoryGb <= 0) {
            throw new IllegalArgumentException("deviceMemoryGb doit être > 0");
        }
    }

    /** Latence d'affichage théorique : {@code (1000 / refreshRateHz) / 2}. */
    public double displayLatencyMs() {
        return (1000.0 / refreshRateHz) / 2.0;
    }

    /**
     * Offset de calibrage à retrancher des temps bruts :
     * {@code displayLatencyMs + inputProcessingLatencyMs}. En fallback (latence
     * d'entrée absente), seul le composant d'affichage est appliqué.
     */
    public double calibrationOffsetMs() {
        return displayLatencyMs() + (inputProcessingLatencyMs != null ? inputProcessingLatencyMs : 0.0);
    }

    /** true si le calibrage est de fiabilité réduite (profil matériel seul). */
    public boolean reducedReliability() {
        return calibrationMethod == CalibrationMethod.HARDWARE_PROFILE_FALLBACK;
    }
}
