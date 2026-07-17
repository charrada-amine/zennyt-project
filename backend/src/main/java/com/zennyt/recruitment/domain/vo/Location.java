package com.zennyt.recruitment.domain.vo;

/**
 * Localisation d'une offre — value object immuable.
 *
 * @param city    ville (ex: "Paris")
 * @param country pays (ex: "France")
 * @param remote  indique si le poste accepte le télétravail
 */
public record Location(String city, String country, boolean remote) {}
