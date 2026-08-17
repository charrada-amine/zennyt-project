package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Entité JPA de la composition d'une forme parallèle
 * (table {@code games.decision_form_items}, V59).
 *
 * <p>Une forme est une <b>liste curatée</b> de 30 items (6 par dimension), pas le
 * résultat d'une règle positionnelle. Voir l'en-tête de V59 pour les deux raisons :
 * intégrité des paires CS, et non-équivalence des formes tant que ER-1..18, CS et
 * RE restent en notation neutre.
 */
@Entity
@Table(name = "decision_form_items", schema = "games")
@IdClass(DecisionFormItemEntity.Key.class)
public class DecisionFormItemEntity {

    @Id
    @Column(name = "form_code", nullable = false, length = 1)
    private String formCode;

    @Id
    @Column(name = "scenario_id", nullable = false)
    private UUID scenarioId;

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
