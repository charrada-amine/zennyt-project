package com.zennyt.games.domain.service;

import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.vo.DifficultyLevel;
import com.zennyt.games.domain.vo.EmotionDefinition;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Random;

/**
 * Sélection <b>dynamique</b> des distracteurs d'une scène, par calcul de distance
 * sémantique (remplace les « familles » prédéfinies manuellement — admin table
 * {@code distractor_selection_method}).
 *
 * <p>Pour un niveau donné, on choisit {@code choicesCount − 1} distracteurs dont la
 * distance à la bonne réponse est la plus <b>proche de la distance cible</b> du
 * niveau : distance élevée → scène facile, distance faible → scène difficile. Le
 * tirage est déterministe pour une graine donnée (rejouabilité, tests, parité mock).
 *
 * <p><b>Point de vigilance produit</b> (brief §1) : pour les catégories restreintes
 * (prosociales : 3, ambivalentes-cognitives : 4), vérifier que chaque émotion dispose
 * d'assez de voisins pertinents en L4 (distance faible). On complète alors avec les
 * voisins les plus proches disponibles plutôt que d'échouer.
 */
public final class DistractorSelectionService {

    private final EmotionReferential referential;
    private final SemanticDistanceModel distanceModel;

    public DistractorSelectionService(EmotionReferential referential,
                                      SemanticDistanceModel distanceModel) {
        this.referential = referential;
        this.distanceModel = distanceModel;
    }

    /**
     * Choix proposés pour une scène : la bonne réponse + les distracteurs, mélangés.
     *
     * @param correct l'émotion réellement jouée dans la vidéo
     * @param level   le niveau courant (porte nombre de choix + distance cible)
     * @param seed    graine de mélange (déterminisme)
     * @return liste ordonnée (mélangée) d'émotions à afficher, {@code correct} incluse
     */
    public List<EmotionDefinition> buildChoices(EmotionDefinition correct,
                                                DifficultyLevel level, long seed) {
        if (correct == null || level == null) {
            throw new IllegalArgumentException("correct et level requis");
        }
        double target = level.targetDistance().target();

        List<EmotionDefinition> candidates = new ArrayList<>(referential.all());
        candidates.removeIf(e -> e.key().equals(correct.key()));
        // Tri par proximité à la distance cible : |distance(candidat, correct) − cible|.
        candidates.sort(Comparator.comparingDouble(
            e -> Math.abs(distanceModel.distance(correct, e) - target)));

        int wanted = Math.min(level.choicesCount() - 1, candidates.size());
        List<EmotionDefinition> choices = new ArrayList<>(candidates.subList(0, wanted));
        choices.add(correct);
        Collections.shuffle(choices, new Random(seed));
        return List.copyOf(choices);
    }

    /** Distance sémantique moyenne des choix à la bonne réponse — difficulté de la scène. */
    public double sceneDifficulty(EmotionDefinition correct, List<EmotionDefinition> choices) {
        return choices.stream()
            .filter(e -> !e.key().equals(correct.key()))
            .mapToDouble(e -> distanceModel.distance(correct, e))
            .average()
            .orElse(1.0);
    }
}
