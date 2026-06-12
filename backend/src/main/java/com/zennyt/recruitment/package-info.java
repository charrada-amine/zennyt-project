/**
 * Bounded Context <b>Recruitment</b> — contexte de référence (hexagonal complet).
 *
 * <p>Responsabilités : publication et recherche d'offres, candidatures et
 * machine à états de leur statut, matching, offres sauvegardées.
 *
 * <p>Événements publiés : {@code JobPublishedEvent}, {@code ApplicationSubmittedEvent}.
 * Propriété : Squad Jobs.
 */
package com.zennyt.recruitment;
