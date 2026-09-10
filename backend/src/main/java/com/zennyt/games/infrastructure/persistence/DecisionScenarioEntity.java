package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Entité JPA d'un item « Je Décide » (table {@code games.decision_scenarios}, V59).
 *
 * <p>Le contenu vient de la banque de 120 items du psychologue, seedée par Flyway
 * depuis {@code resources/games/decision_scenarios.json}.
 */
@Entity
@Table(name = "decision_scenarios", schema = "games")
public class DecisionScenarioEntity {

    @Id
    private UUID id;

    @Column(name = "item_id", nullable = false, length = 20)
    private String itemId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 2)
    private DecisionDimension dimension;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DecisionItemFormat format;

    @Column(name = "pair_id", length = 20)
    private String pairId;

    /** Null pour les items DT : ils réutilisent la vignette de {@link #vignetteRef}. */
    @Column(name = "vignette")
    private String vignette;

    @Column(name = "vignette_ref", length = 20)
    private String vignetteRef;

    @Column(name = "task", nullable = false)
    private String task;

    @Column(name = "optimal_option", length = 40)
    private String optimalOption;

    @Column(name = "provisional_scoring", nullable = false)
    private boolean provisionalScoring;

    @Column(name = "position", nullable = false)
    private int position;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "scenario_id")
    @OrderBy("position ASC")
    private List<DecisionScenarioOptionEntity> options = new ArrayList<>();

    protected DecisionScenarioEntity() { } // requis par JPA

    public UUID getId() { return id; }
    public String getItemId() { return itemId; }
    public DecisionDimension getDimension() { return dimension; }
    public DecisionItemFormat getFormat() { return format; }
    public String getPairId() { return pairId; }
    public String getVignette() { return vignette; }
    public String getVignetteRef() { return vignetteRef; }
    public String getTask() { return task; }
    public String getOptimalOption() { return optimalOption; }
    public boolean isProvisionalScoring() { return provisionalScoring; }
    public int getPosition() { return position; }
    public List<DecisionScenarioOptionEntity> getOptions() { return options; }
}
