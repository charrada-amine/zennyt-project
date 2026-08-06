package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.CandidateOfferPair;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Sérialise une liste de paires en deux chaînes parallèles, pour les requêtes natives qui
 * utilisent {@code unnest(string_to_array(...), string_to_array(...))}.
 *
 * <p>L'ordre est significatif : la n-ième valeur de {@code candidateIds} et la n-ième de
 * {@code jobOfferIds} forment une paire. C'est ce parallélisme qui permet à PostgreSQL de
 * cibler les paires exactes plutôt que leur produit croisé.
 */
final class PairArrays {
    private PairArrays() {}

    static String candidateIds(List<CandidateOfferPair> pairs) {
        return pairs.stream().map(p -> p.candidateId().toString()).collect(Collectors.joining(","));
    }

    static String jobOfferIds(List<CandidateOfferPair> pairs) {
        return pairs.stream().map(p -> p.jobOfferId().toString()).collect(Collectors.joining(","));
    }
}
