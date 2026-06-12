/**
 * Bounded Context <b>Identity</b>.
 *
 * <p>Responsabilités : inscription, authentification (Azure AD B2C, OAuth2 PKCE),
 * gestion des jetons JWT, profils candidat et recruteur, CV et compétences.
 *
 * <p>Événements publiés : {@code UserRegisteredEvent}, {@code ProfileCompletedEvent}.
 * Propriété : Squad Identity.
 */
package com.zennyt.identity;
