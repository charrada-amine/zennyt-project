package com.zennyt.games.domain.vo;

/**
 * Server-graded result of one Emotional Radar V2 scene. The extended metadata
 * describes the served stimulus; the compatibility constructor keeps the
 * original pure-domain fixtures valid.
 */
public record RadarSceneOutcome(
    int sceneOrder,
    int level,
    int choicesCount,
    double sceneDifficulty,
    DistanceBand targetDistanceBand,
    StimulusType stimulusType,
    String correctKey,
    String selectedKey,
    boolean correct,
    double semanticErrorDist,
    int stimulusIntensity,
    int selectedIntensity,
    int responseTimeMs,
    boolean impulsive,
    int justificationScore,
    boolean timedOut
) {
    public RadarSceneOutcome {
        if (correctKey == null || selectedKey == null) {
            throw new IllegalArgumentException("correctKey et selectedKey requis");
        }
        if (level < 1) throw new IllegalArgumentException("level ≥ 1 requis : " + level);
        if (choicesCount < 2) throw new IllegalArgumentException("choicesCount ≥ 2 requis");
        if (semanticErrorDist < 0.0 || semanticErrorDist > 1.0) {
            throw new IllegalArgumentException("semanticErrorDist hors [0,1]");
        }
    }

    /** Original report/scoring fixture shape, before persisted stimulus metadata. */
    public RadarSceneOutcome(int sceneOrder, int level, int choicesCount,
                             double sceneDifficulty, String correctKey,
                             String selectedKey, boolean correct,
                             double semanticErrorDist, int stimulusIntensity,
                             int selectedIntensity, int responseTimeMs,
                             boolean impulsive, int justificationScore) {
        this(sceneOrder, level, choicesCount, sceneDifficulty, null, null,
            correctKey, selectedKey, correct, semanticErrorDist,
            stimulusIntensity, selectedIntensity, responseTimeMs, impulsive,
            justificationScore, false);
    }

    public boolean intensityMatches() { return stimulusIntensity == selectedIntensity; }

    public int intensityErrorDirection() {
        return Integer.compare(selectedIntensity, stimulusIntensity);
    }
}
