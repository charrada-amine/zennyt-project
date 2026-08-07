package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.FitScore;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Écrit les scores calculés à l'affichage, dans une transaction <b>séparée</b> de la
 * requête de lecture.
 *
 * <p>Raison d'être : {@code GetSwipeDeckUseCase} est {@code @Transactional(readOnly = true)}.
 * Écrire en rejoignant cette transaction échouerait, et l'élargir ferait d'une requête de
 * lecture très fréquente une transaction d'écriture — exactement la pression qu'on cherche
 * à éviter. {@code REQUIRES_NEW} garde l'écriture courte et indépendante : si elle échoue,
 * la lecture continue normalement.
 *
 * <p>Bean distinct de {@link InlineFitScoreComputer} par nécessité technique : Spring
 * applique {@code @Transactional} via un proxy, donc un appel interne à la même classe ne
 * déclencherait pas la nouvelle transaction.
 */
@Component
public class InlineFitScoreWriter {

    private final RecomputeFitScoresUseCase recompute;

    public InlineFitScoreWriter(RecomputeFitScoresUseCase recompute) {
        this.recompute = recompute;
    }

    /**
     * Calcule et persiste le lot fourni. Réutilise <b>exactement</b> le chemin par lot du
     * balayage — aucune logique de calcul dupliquée, donc le test d'équivalence entre
     * chemin unitaire et chemin par lot reste valable pour le calcul à l'affichage aussi.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public List<FitScore> computeAndPersist(List<RecomputeFitScoresUseCase.Pair> pairs) {
        return recompute.recomputeBatch(pairs);
    }
}
