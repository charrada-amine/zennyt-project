package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.model.MiniGame;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

import java.time.Instant;

/**
 * Représentation persistée d'un {@code Attempt} — {@code @Embeddable} stocké
 * dans une table fille via {@code @ElementCollection} de {@link GameSessionEntity}.
 *
 * <p>Volontairement distincte de l'entité de domaine : le domaine reste pur,
 * l'adaptateur repository fait la conversion.
 */
@Embeddable
public class AttemptEmbeddable {

    @Enumerated(EnumType.STRING)
    @Column(name = "mini_game", nullable = false)
    private MiniGame miniGame;

    @Column(name = "raw_points", nullable = false)
    private int rawPoints;

    @Column(name = "max_points", nullable = false)
    private int maxPoints;

    @Column(name = "level", nullable = false)
    private String level;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    protected AttemptEmbeddable() { } // requis par JPA

    public AttemptEmbeddable(MiniGame miniGame, int rawPoints, int maxPoints,
                             String level, Instant recordedAt) {
        this.miniGame = miniGame;
        this.rawPoints = rawPoints;
        this.maxPoints = maxPoints;
        this.level = level;
        this.recordedAt = recordedAt;
    }

    public MiniGame getMiniGame() { return miniGame; }
    public int getRawPoints() { return rawPoints; }
    public int getMaxPoints() { return maxPoints; }
    public String getLevel() { return level; }
    public Instant getRecordedAt() { return recordedAt; }
}
