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
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Index;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.util.ArrayList;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Entité JPA d'un item « Je Décide » (table {@code games.decision_scenarios}, V59).
 *
 * <p>Le contenu vient de la banque de 120 items du psychologue
 * ({@code resources/games/decision_scenarios.json}), insérée par les données de référence
 * ({@code db/reference-data.sql}).
 */
@Entity
@Table(name = "decision_scenarios", schema = "games",
    uniqueConstraints = @UniqueConstraint(name = "ux_decision_scenarios_item", columnNames = {"item_id"}),
    indexes = @Index(name = "ix_decision_scenarios_dimension", columnList = "dimension, position"))
@Check(name = "ck_decision_scenarios_dimension", constraints = "dimension IN ('II', 'ER', 'DT', 'CS', 'RE')")
@Check(name = "ck_decision_scenarios_format", constraints = "format IN ('STANDARD', 'TEMPORAL_DECISION', 'COHERENCE_PAIR')")
@Check(name = "ck_decision_scenarios_pair", constraints = "(format = 'COHERENCE_PAIR') = (pair_id IS NOT NULL)")
@Check(name = "ck_decision_scenarios_position", constraints = "position >= 1")
@Check(name = "ck_decision_scenarios_vignette", constraints = "(vignette IS NOT NULL) <> (vignette_ref IS NOT NULL)")
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
    @Column(name = "vignette", length = Length.LONG32)
    private String vignette;

    @Column(name = "vignette_ref", length = 20)
    private String vignetteRef;

    @Column(name = "task", nullable = false, length = Length.LONG32)
    private String task;

    @Column(name = "optimal_option", length = 40)
    private String optimalOption;

    @Column(name = "provisional_scoring", nullable = false)
    private boolean provisionalScoring;

    @Column(name = "position", nullable = false)
    private int position;

    /** Horodatages d'audit, alimentés par la base ({@code DEFAULT now()}) : jamais écrits ici. */
    @ColumnDefault("now()")
    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private Instant createdAt;

    @ColumnDefault("now()")
    @Column(name = "updated_at", nullable = false, insertable = false, updatable = false)
    private Instant updatedAt;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "scenario_id", nullable = false,
        foreignKey = @ForeignKey(name = "decision_scenario_options_scenario_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
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
