package com.zennyt.engagement.domain.vo;

/**
 * Statut d'un parrainage. Le bonus n'est dû qu'après la période d'essai du
 * recrutement (voir {@code Referral} et le §12 des Conditions d'utilisation).
 */
public enum ReferralStatus {
    /** Invitation envoyée, filleul pas encore inscrit. */
    INVITED,
    /** Le filleul s'est inscrit avec le lien. */
    REGISTERED,
    /** Le filleul a été recruté et sa période d'essai est validée. */
    HIRED,
    /** Parrainage annulé (fraude, doublon, retrait). */
    CANCELLED
}
