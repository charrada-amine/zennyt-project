package com.zennyt.games.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Repository Spring Data technique du catalogue « Je Décide » (V59). */
public interface JpaDecisionScenarioRepository
    extends JpaRepository<DecisionScenarioEntity, UUID> {

    Optional<DecisionScenarioEntity> findByItemId(String itemId);

    List<DecisionScenarioEntity> findByItemIdIn(Collection<String> itemIds);

    /**
     * Items d'une forme, dans l'ordre de passation.
     *
     * <p>La composition d'une forme est une <b>donnée</b> ({@code decision_form_items}),
     * pas une règle positionnelle : les paires CS doivent rester groupées, et un item
     * DT ne doit jamais côtoyer l'item II dont il réutilise la vignette.
     */
    @Query("""
        select s
          from DecisionFormItemEntity f
          join DecisionScenarioEntity s on s.id = f.scenarioId
         where f.formCode = :formCode
         order by f.position asc
        """)
    List<DecisionScenarioEntity> findFormItems(@Param("formCode") String formCode);
}
