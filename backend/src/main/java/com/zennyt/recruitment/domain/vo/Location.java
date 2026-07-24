package com.zennyt.recruitment.domain.vo;

/**
 * Localisation d'une offre — value object immuable.
 *
 * <p>Pas de champ {@code remote} : redondant avec {@code workplaceType: REMOTE}
 * (contrat squad web, §3.1).
 *
 * @param city    ville (ex: "Paris")
 * @param country pays (ex: "France")
 */
public record Location(String city, String country) {}
