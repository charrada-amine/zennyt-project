package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Entité JPA de la composition d'une forme parallèle
 * (table {@code games.decision_form_items}, V59).
 *
 * <p>Une forme est une <b>liste curatée</b> de 30 items (6 par dimension), pas le
 * résultat d'une règle positionnelle, pour deux raisons : intégrité des paires CS (une
 * règle positionnelle couperait CS-1a de CS-1b), et non-équivalence des formes tant que
 * ER-1..18, CS et RE restent en notation neutre. Seule la forme A est dans les données de
 * référence ({@code db/reference-data.sql}).
 */
@Entity
@Table(name = "decision_form_items", schema = "games", uniqueConstraints = {
    @UniqueConstraint(name = "ux_decision_form_position", columnNames = {"form_code", "position"}),
    // Ordre des colonnes de la clé primaire, fusionné dans decision_form_items_pkey.
    @UniqueConstraint(name = "decision_form_items_pkey", columnNames = {"form_code", "scenario_id"})})
@Check(name = "ck_decision_form_code", constraints = "form_code IN ('A', 'B', 'C', 'D')")
@Check(name = "ck_decision_form_position", constraints = "position >= 1 AND position <= 30")
@IdClass(DecisionFormItemEntity.Key.class)
public class DecisionFormItemEntity {

    @Id
    @Column(name = "form_code", nullable = false, length = 1)
    private String formCode;

    @Id
    @Column(name = "scenario_id", nullable = false)
    private UUID scenarioId;

    /** Clé étrangère {@code games.decision_scenarios(id) ON DELETE RESTRICT} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "scenario_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "decision_form_items_scenario_id_fkey"))
    @OnDelete(action = OnDeleteAction.RESTRICT)
    private DecisionScenarioEntity scenario;

    @Column(name = "position", nullable = false)
    private int position;

    protected DecisionFormItemEntity() { } // requis par JPA

    public String getFormCode() { return formCode; }
    public UUID getScenarioId() { return scenarioId; }
    public int getPosition() { return position; }

    /** Clé composite (forme, scénario). */
    public static class Key implements Serializable {
        private String formCode;
        private UUID scenarioId;

        protected Key() { }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(formCode, other.formCode)
                && Objects.equals(scenarioId, other.scenarioId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(formCode, scenarioId);
        }
    }
}
