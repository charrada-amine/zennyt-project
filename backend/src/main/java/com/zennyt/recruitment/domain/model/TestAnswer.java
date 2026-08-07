package com.zennyt.recruitment.domain.model;

import java.util.UUID;

/**
 * Réponse notée d'un candidat à une question (contrat squad web §7.1).
 *
 * @param selectedOptionIndex index d'option original (démélangé), pas la
 *                            position affichée au candidat
 */
public record TestAnswer(UUID questionId, int selectedOptionIndex, boolean correct) {}
