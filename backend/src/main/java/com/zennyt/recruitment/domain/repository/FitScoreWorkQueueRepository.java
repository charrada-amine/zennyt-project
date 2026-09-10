package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.vo.CandidateOfferPair;

import java.util.List;

/**
 * File de travail durable du Fit Score.
 *
 * <p>Point d'architecture : cette file <b>a le droit d'échouer</b>. Elle n'est pas la
 * garantie de correction — c'est le calcul à l'affichage qui l'est. Une paire abandonnée
 * ici sera recalculée dès que quelqu'un regardera la liste. La file ne fait qu'éviter que
 * ce calcul ait à s'exécuter, ce qui change complètement le niveau d'exigence : une panne
 * de la file dégrade la fraîcheur, jamais la justesse.
 */
public interface FitScoreWorkQueueRepository {

    /** 0 = urgent (déclenché par un événement), 1 = normal (rattrapage de fond). */
    int PRIORITY_URGENT = 0;
    int PRIORITY_NORMAL = 1;

    /**
     * Ajoute les paires à traiter. Les paires déjà en attente sont ignorées silencieusement
     * (index unique partiel + {@code ON CONFLICT DO NOTHING}) : republier dix fois la même
     * offre n'enfile pas dix fois le même travail.
     *
     * @return le nombre de lignes réellement insérées
     */
    int enqueue(List<CandidateOfferPair> pairs, int priority);

    /**
     * Réserve jusqu'à {@code limit} paires prêtes à être traitées, les plus prioritaires et
     * les plus anciennes d'abord.
     *
     * <p>Utilise {@code FOR UPDATE SKIP LOCKED} : plusieurs workers peuvent tirer en
     * parallèle sans jamais se bloquer. C'est la différence structurelle avec le balayage
     * par lots — on monte en charge en ajoutant des workers, pas en gonflant un lot.
     */
    List<QueuedPair> claim(int limit);

    /** Marque les lignes traitées avec succès. */
    void complete(List<Long> ids);

    /**
     * Enregistre un échec : incrémente le compteur, programme le prochain essai en backoff
     * exponentiel, et bascule en {@code FAILED} au-delà de {@code maxAttempts}.
     */
    void fail(long id, String error, int maxAttempts);

    /** Profondeur de la file en attente pour une priorité donnée. */
    long depth(int priority);

    /** Âge en secondes de la plus ancienne ligne en attente, 0 si la file est vide. */
    long oldestPendingAgeSeconds();

    /**
     * Supprime les lignes terminées plus vieilles que {@code retentionDays}.
     *
     * <p>Sans cela la table ne fait que croître : une ligne est écrite par paire
     * candidat × offre traitée, et rien ne l'efface une fois passée à DONE. Les index
     * étant partiels sur {@code PENDING}, les performances ne se dégradent pas — c'est
     * l'espace disque qui part, silencieusement, sur un volume proportionnel au produit
     * des candidats par les offres.
     *
     * <p>Les lignes FAILED sont conservées : elles sont le seul témoignage d'un calcul
     * abandonné, et leur volume est borné par {@code max-attempts}.
     *
     * @return le nombre de lignes supprimées
     */
    int purgeCompletedOlderThan(int retentionDays);

    /** Nombre de lignes abandonnées — à surveiller : c'est un signal de bug, pas une urgence. */
    long failedCount();

    /** Une ligne réservée : son identifiant de file et la paire à calculer. */
    record QueuedPair(long id, CandidateOfferPair pair) {}
}
