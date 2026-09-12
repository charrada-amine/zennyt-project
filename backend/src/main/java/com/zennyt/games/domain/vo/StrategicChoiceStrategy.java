package com.zennyt.games.domain.vo;

/**
 * Stratégie de régulation choisie dans « Choix Stratégiques ».
 *
 * <p>Les huit stratégies du référentiel, dans l'ordre du document. Le client
 * n'envoie que ce nom et l'identifiant de la situation : la cotation, elle,
 * appartient au catalogue serveur — sans quoi un client pourrait s'attribuer
 * les points de son choix.
 */
public enum StrategicChoiceStrategy {
    AVOID_FLEE,
    RUMINATE,
    BREATHE_PAUSE,
    COGNITIVE_REAPPRAISAL,
    ASSERTIVE_COMMUNICATION,
    HUMOR,
    SEEK_SUPPORT,
    DIRECT_ACTION
}
