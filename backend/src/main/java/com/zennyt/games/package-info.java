/**
 * Bounded Context <b>Games</b> — jeux sérieux d'évaluation cognitive.
 *
 * <p>Responsabilités : administrer des sessions de jeux sérieux (Planifik,
 * Memory Quest, Choix&Cap), calculer un score déterministe à partir des
 * métriques de jeu remontées par le client, et publier le résultat.
 *
 * <p>Ce contexte est volontairement <b>indépendant</b> : il ne dépend d'aucun
 * autre bounded context (seulement de {@code shared}). L'intégration avec le
 * reste de la plateforme se fait uniquement par Domain Event
 * ({@code GameResultRecordedEvent}), consommé par {@code analytics} /
 * {@code engagement}. Il peut donc être développé, testé et déployé seul, puis
 * branché plus tard sans refonte.
 *
 * <p>Événements publiés : {@code GameResultRecordedEvent}.
 */
package com.zennyt.games;
