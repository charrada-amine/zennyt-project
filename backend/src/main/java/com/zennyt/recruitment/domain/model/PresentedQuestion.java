package com.zennyt.recruitment.domain.model;

import java.util.List;
import java.util.UUID;

/**
 * Mapping de mélange pour une question, propre à une tentative (contrat squad
 * web §7.1) — jamais sérialisé dans une réponse API.
 *
 * @param questionId  id stable de la question dans l'{@link Assessment} d'origine
 * @param order       position d'affichage (1-based) après mélange des questions
 * @param optionOrder permutation des options : {@code optionOrder.get(i)} est
 *                    l'index original de l'option affichée en position {@code i}
 */
public record PresentedQuestion(UUID questionId, int order, List<Integer> optionOrder) {}
