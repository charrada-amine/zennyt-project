package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.OptionQuality;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

/**
 * Entité JPA d'une option de réponse (table {@code games.decision_scenario_options}).
 *
 * <p>{@code quality} est la <b>clé de correction</b> : elle fait autorité côté
 * serveur et ne doit jamais être sérialisée vers le client. Le score /3 n'est pas
 * stocké — il est porté par {@link OptionQuality#points()}, seule source de vérité.
 */
@Entity
@Table(name = "decision_scenario_options", schema = "games")
public class DecisionScenarioOptionEntity {

    @Id
    private UUID id;

    @Column(name = "option_id", nullable = false, length = 40)
    private String optionId;

    @Column(name = "label", nullable = false)
    private String label;

    @Enumerated(EnumType.STRING)
    @Column(name = "quality", nullable = false, length = 16)
    private OptionQuality quality;

    @Column(name = "position", nullable = false)
    private int position;

    protected DecisionScenarioOptionEntity() { } // requis par JPA

    public UUID getId() { return id; }
    public String getOptionId() { return optionId; }
    public String getLabel() { return label; }
    public OptionQuality getQuality() { return quality; }
    public int getPosition() { return position; }
}
