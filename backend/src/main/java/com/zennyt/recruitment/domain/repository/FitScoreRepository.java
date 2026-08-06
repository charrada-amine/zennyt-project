package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;

import java.util.Optional;
import java.util.List;
import java.util.UUID;

/**
 * Port du repository de scores de compatibilité.
 */
public interface FitScoreRepository {

    FitScore save(FitScore fitScore);

    /** Score entre un candidat et une offre (calculé par l'IA). */
    Optional<FitScore> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    List<FitScore> findByJobOfferIdOrderByScoreDesc(UUID jobOfferId);

    List<FitScore> findByCandidateIdAndJobOfferIds(UUID candidateId, List<UUID> jobOfferIds);

    /**
     * Variante multi-candidats — une seule requête pour tout un lot de recalcul.
     *
     * <p>Cible <b>exactement</b> les paires demandées : ni sur-lecture, ni filtrage en
     * mémoire côté appelant. Voir {@link CandidateOfferPair}.
     */
    List<FitScore> findByPairs(List<CandidateOfferPair> pairs);

    /** Paire (candidat, offre) en attente de calcul — backlog du balayage de rattrapage. */
    record PairNeedingScore(UUID candidateId, UUID jobOfferId) {}

    /**
     * Paires (candidat actif, offre ACTIVE) sans score, les plus anciennement en attente
     * d'abord, bornées par {@code limit}.
     */
    List<PairNeedingScore> findPairsNeedingScore(int limit);

    /**
     * Paires dont le score existe mais a été calculé avant la dernière évolution de
     * l'offre, des soft skills du candidat ou de son résultat de test — les plus
     * anciennement calculées d'abord, bornées par {@code limit}.
     */
    List<PairNeedingScore> findStalePairs(int limit);

    /**
     * Profondeur du retard : nombre total de paires manquantes ou périmées, sans borne
     * de lot. C'est le seul indicateur qui prévient <b>avant</b> la saturation — un test
     * fonctionnel passe encore la veille du jour où le balayage ne suit plus.
     *
     * <p>Volontairement plus coûteux que les requêtes bornées (aucun {@code LIMIT}), donc
     * relevé moins souvent que le balayage lui-même. Auto-signalant : ce comptage devient
     * lourd exactement quand le retard devient important, c'est-à-dire au moment où il
     * faut de toute façon revoir l'architecture.
     */
    long countPairsNeedingScore();

    /**
     * Supprime tous les scores d'une offre — appelé quand elle est fermée : ses scores
     * ne sont plus consultables et ne feraient que grossir la table, alourdissant
     * l'anti-jointure du balayage.
     *
     * @return le nombre de scores supprimés
     */
    int deleteByJobOfferId(UUID jobOfferId);

    /**
     * Écriture par lot — même upsert que {@link #save}, une seule transaction pour tout le lot.
     *
     * <p>Contrairement à {@link #save}, ne relit pas chaque ligne après écriture (le chemin
     * par lot n'a pas besoin de l'entité persistée) : cela économise une requête par paire.
     *
     * @return le nombre de scores soumis à l'upsert
     */
    int saveAll(List<FitScore> fitScores);
}
