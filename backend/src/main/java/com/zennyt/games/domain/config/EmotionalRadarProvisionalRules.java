package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.BasicEmotion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Couche <b>PROVISOIRE</b> d'« Emotional Radar » — un seul fichier, chaque valeur
 * commentée {@code // PROVISOIRE}.
 *
 * <p>Même patron strict que {@code DecisionProvisionalRules} : le moteur de
 * notation ({@code EmotionalRadarScoringService}) ne code <b>jamais</b> une de ces
 * valeurs en dur, il les lit ici. Remplacer le provisoire par les données du
 * psychologue ne demande <b>aucune</b> modification du moteur.
 *
 * <p><b>Ce qui vient de la maquette et ne doit PAS être écrasé sans arbitrage :</b>
 * la liste complète des nuances de {@code SADNESS} (écran « 04 Emotion Selected »),
 * ainsi que {@code FEAR → Anxiety} et {@code JOY → Excitement/Triumph}, lisibles
 * dans les cartes de feedback. Ces entrées portent {@link NuanceSource#FIGMA}.
 *
 * <p><b>Ce qui est provisoire :</b> les nuances d'ANGER, DISGUST et SURPRISE —
 * absentes de toutes les planches alors que les six familles sont sélectionnables
 * dès l'étape 1 — ainsi que le complément des familles partiellement documentées.
 * Elles reprennent les sous-catégories usuelles du modèle d'Ekman et portent
 * {@link NuanceSource#PROVISIONAL}.
 */
public final class EmotionalRadarProvisionalRules {

    private EmotionalRadarProvisionalRules() {
    }

    /** Origine d'une nuance : maquette fournie, ou ajout provisoire à valider. */
    public enum NuanceSource {
        /** Lisible sur une planche Figma — fait autorité. */
        FIGMA,
        /** Ajout développeur (Ekman) — à valider par le psychologue. */
        PROVISIONAL
    }

    /** Une nuance sélectionnable, avec son origine. */
    public record Nuance(String key, String label, NuanceSource source) {
    }

    private static Nuance figma(String key, String label) {
        return new Nuance(key, label, NuanceSource.FIGMA);
    }

    private static Nuance provisional(String key, String label) {
        return new Nuance(key, label, NuanceSource.PROVISIONAL);
    }

    /**
     * Taxonomie émotion → nuances.
     *
     * <p>L'ordre est significatif : il pilote l'ordre d'affichage des chips.
     * Pour SADNESS, il reproduit exactement celui de la maquette
     * (Disappointment, Nostalgia, Empathic pain, Sympathy, Guilt).
     */
    private static final Map<BasicEmotion, List<Nuance>> NUANCES = buildNuances();

    private static Map<BasicEmotion, List<Nuance>> buildNuances() {
        Map<BasicEmotion, List<Nuance>> map = new LinkedHashMap<>();

        // ── SADNESS — intégralement fournie par la maquette (écran 04) ────────
        map.put(BasicEmotion.SADNESS, List.of(
            figma("DISAPPOINTMENT", "Disappointment"),
            figma("NOSTALGIA", "Nostalgia"),
            figma("EMPATHIC_PAIN", "Empathic pain"),
            figma("SYMPATHY", "Sympathy"),
            figma("GUILT", "Guilt")));

        // ── FEAR — seule « Anxiety » est attestée (carte de feedback scène 2) ─
        map.put(BasicEmotion.FEAR, List.of(
            figma("ANXIETY", "Anxiety"),
            provisional("APPREHENSION", "Apprehension"), // PROVISOIRE — Ekman
            provisional("NERVOUSNESS", "Nervousness"),   // PROVISOIRE — Ekman
            provisional("DREAD", "Dread"),               // PROVISOIRE — Ekman
            provisional("PANIC", "Panic")));             // PROVISOIRE — Ekman

        // ── JOY — « Excitement » et « Triumph » attestées (cartes de feedback) ─
        map.put(BasicEmotion.JOY, List.of(
            figma("EXCITEMENT", "Excitement"),
            figma("TRIUMPH", "Triumph"),
            provisional("CONTENTMENT", "Contentment"),   // PROVISOIRE — Ekman
            provisional("PRIDE", "Pride"),               // PROVISOIRE — Ekman
            provisional("RELIEF", "Relief")));           // PROVISOIRE — Ekman

        // ── ANGER — AUCUNE nuance sur les planches ───────────────────────────
        map.put(BasicEmotion.ANGER, List.of(
            provisional("IRRITATION", "Irritation"),     // PROVISOIRE — Ekman
            provisional("FRUSTRATION", "Frustration"),   // PROVISOIRE — Ekman
            provisional("INDIGNATION", "Indignation"),   // PROVISOIRE — Ekman
            provisional("RESENTMENT", "Resentment"),     // PROVISOIRE — Ekman
            provisional("RAGE", "Rage")));               // PROVISOIRE — Ekman

        // ── DISGUST — AUCUNE nuance sur les planches ─────────────────────────
        map.put(BasicEmotion.DISGUST, List.of(
            provisional("DISTASTE", "Distaste"),         // PROVISOIRE — Ekman
            provisional("AVERSION", "Aversion"),         // PROVISOIRE — Ekman
            provisional("REVULSION", "Revulsion"),       // PROVISOIRE — Ekman
            provisional("CONTEMPT", "Contempt"),         // PROVISOIRE — Ekman
            provisional("DISAPPROVAL", "Disapproval"))); // PROVISOIRE — Ekman

        // ── SURPRISE — AUCUNE nuance sur les planches ────────────────────────
        map.put(BasicEmotion.SURPRISE, List.of(
            provisional("ASTONISHMENT", "Astonishment"), // PROVISOIRE — Ekman
            provisional("AMAZEMENT", "Amazement"),       // PROVISOIRE — Ekman
            provisional("STARTLE", "Startle"),           // PROVISOIRE — Ekman
            provisional("CONFUSION", "Confusion"),       // PROVISOIRE — Ekman
            provisional("CURIOSITY", "Curiosity")));     // PROVISOIRE — Ekman

        return Map.copyOf(map);
    }

    /** Nuances sélectionnables pour une famille, dans l'ordre d'affichage. */
    public static List<Nuance> nuancesFor(BasicEmotion emotion) {
        return NUANCES.getOrDefault(emotion, List.of());
    }

    /** Taxonomie complète (ordre des familles = ordre de la grille de l'écran). */
    public static Map<BasicEmotion, List<Nuance>> allNuances() {
        return NUANCES;
    }

    /** La nuance appartient-elle bien à cette famille ? */
    public static boolean isValidNuance(BasicEmotion emotion, String nuanceKey) {
        if (nuanceKey == null) {
            return false;
        }
        return nuancesFor(emotion).stream()
            .anyMatch(n -> n.key().equalsIgnoreCase(nuanceKey.trim()));
    }

    /**
     * Bandes d'interprétation (/100).
     *
     * <p>⚠️ PROVISOIRE — aucune fiche ne les fournit pour la régulation émotionnelle.
     * Alignées sur celles des autres jeux (Move Fast, « J'investigue ») pour rester
     * cohérentes tant que le psychologue n'a pas tranché.
     */
    public static String interpret(double normalized) {
        if (normalized < 40) {
            return "Très faible";   // PROVISOIRE
        }
        if (normalized < 60) {
            return "Moyen faible";  // PROVISOIRE
        }
        if (normalized < 75) {
            return "Moyen";         // PROVISOIRE
        }
        if (normalized < 90) {
            return "Bon";           // PROVISOIRE
        }
        return "Excellent";         // PROVISOIRE
    }
}
