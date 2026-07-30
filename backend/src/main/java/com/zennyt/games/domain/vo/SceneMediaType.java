package com.zennyt.games.domain.vo;

/**
 * Support d'une scène d'« Emotional Radar ».
 *
 * <p>DIALOGUE et TEXT sont purement textuels ; IMAGE et VIDEO s'appuient sur un
 * média stocké côté backend. La planche « Accessibility Compliance » impose un
 * équivalent textuel pour tout média, et des sous-titres/transcription pour la
 * vidéo : ces contraintes sont portées par {@link EmotionalRadarScene}, pas
 * seulement par la base.
 */
public enum SceneMediaType {
    DIALOGUE,
    TEXT,
    IMAGE,
    VIDEO;

    /** Un média externe (et donc un équivalent textuel) est-il attendu ? */
    public boolean requiresMedia() {
        return this == IMAGE || this == VIDEO;
    }

    /** La vidéo exige en plus une transcription / des sous-titres. */
    public boolean requiresTranscript() {
        return this == VIDEO;
    }
}
