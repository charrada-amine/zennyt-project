package com.zennyt.games.domain.config;

/**
 * Couche <b>PROVISOIRE</b> d'« Emotional Radar v2 » — un seul fichier, chaque valeur
 * commentée {@code // PROVISOIRE}. Même patron strict que
 * {@link DecisionProvisionalRules} : le moteur (score « jeu », theta, interprétation)
 * ne code jamais ces valeurs en dur, il les lit ici. Remplacer le provisoire par les
 * données de calibration ne demande aucune modification du moteur.
 */
public final class EmotionalRadarV2ProvisionalRules {

    private EmotionalRadarV2ProvisionalRules() {
    }

    // ═══ Phase A delivery gates ══════════════════════════════════════════════

    /** The normed 135-video library is not available yet. PROVISOIRE. */
    public static final boolean MEDIA_LIBRARY_READY = false;

    /** The visible game score remains provisional until media norming. PROVISOIRE. */
    public static final boolean SCORING_PROVISIONAL = true;

    /** A placeholder run must never publish into Fit Score. PROVISOIRE. */
    public static final boolean FIT_SCORE_PUBLISHING_ALLOWED = false;

    /** Phase A placeholders are not a psychometric measurement. PROVISOIRE. */
    public static final boolean MEASUREMENT_AVAILABLE = false;

    // ═══ Score « jeu » (radar_emotion_score, 0–10) ═══════════════════════════
    // PROVISOIRE — le brief dit « basé sur les niveaux, façon jeu vidéo » sans donner
    // la formule. On combine le niveau atteint (poids majeur) et la précision globale.

    /** Poids du niveau final dans le score « jeu » (0..1). PROVISOIRE. */
    public static final double GAME_SCORE_LEVEL_WEIGHT = 0.7;

    /** Poids de la précision globale dans le score « jeu » (0..1). PROVISOIRE. */
    public static final double GAME_SCORE_ACCURACY_WEIGHT = 0.3;

    /** Bornes d'interprétation du niveau global (emotional_level). PROVISOIRE. */
    public static final double EMOTIONAL_LEVEL_HIGH_MIN = 7.0;  // ≥ 7/10 → Élevé
    public static final double EMOTIONAL_LEVEL_MEDIUM_MIN = 4.0; // ≥ 4/10 → Moyen

    /** Niveau global textuel à partir du score « jeu » /10. PROVISOIRE. */
    public static String emotionalLevel(double gameScore) {
        if (gameScore >= EMOTIONAL_LEVEL_HIGH_MIN) return "Élevé";
        if (gameScore >= EMOTIONAL_LEVEL_MEDIUM_MIN) return "Moyen";
        return "Faible";
    }

    // ═══ Couche décisionnelle theta (IRT) — VERROUILLÉE tant que non calibrée ═
    // PROVISOIRE — le brief interdit tout usage décisionnel/RH/clinique tant que la
    // calibration (section 4) n'est pas « Validé ». Ces valeurs sont des points de
    // départ théoriques (2PL), à remplacer par des paramètres empiriques.

    /**
     * {@code decisional_use_allowed} — le theta ne doit JAMAIS servir à comparer des
     * personnes tant que ce drapeau est {@code false}. Ne le passer à {@code true}
     * qu'une fois {@code calibration_status = Validé} (plan §4 du brief).
     */
    public static final boolean DECISIONAL_USE_ALLOWED = false; // PROVISOIRE — NE PAS activer

    /** {@code min_items_for_reliable_theta} — sous ce seuil, theta = « Provisoire ». PROVISOIRE. */
    public static final int MIN_ITEMS_FOR_RELIABLE_THETA = 20;

    /** Discrimination 2PL par item (paramètre a). PROVISOIRE — 1.0 faute de calibration. */
    public static final double IRT_DISCRIMINATION = 1.0;

    /**
     * Amplitude de conversion « distance sémantique → difficulté d'item (b) ».
     * Difficulté théorique b = (0.5 − distance) × ÉCHELLE : distance faible (émotions
     * proches) → item difficile (b élevé). PROVISOIRE.
     */
    public static final double IRT_DIFFICULTY_SCALE = 4.0;

    /** Difficulté 2PL théorique d'un item depuis la distance sémantique de la scène. PROVISOIRE. */
    public static double itemDifficultyFromDistance(double semanticDistance) {
        return (0.5 - semanticDistance) * IRT_DIFFICULTY_SCALE; // PROVISOIRE
    }

    // ═══ Footage de démonstration ════════════════════════════════════════════

    /**
     * Les seules vidéos réellement disponibles : 3 des 135 attendues. PROVISOIRE.
     *
     * <p>Le rattachement se fait par <b>émotion</b>, jamais par ordre de scène.
     * Rattacher un clip à « la scène 1 » montrerait une femme inquiète alors que
     * la réponse attendue serait « Joie » : la vidéo contredirait la correction,
     * ce qui est pire qu'un placeholder. Ce choix appartient au serveur parce
     * que le client ignore l'émotion cible — et doit continuer à l'ignorer.
     *
     * <p>Les trois clips couvrent par chance les trois cadrages du référentiel :
     * facial, corporel et contextuel. Le contextuel exige une légende, fournie
     * ici — factuelle, sans mot d'émotion, conformément à la consigne « aucun
     * texte ne doit révéler l'émotion à identifier ».
     *
     * <p>Le chemin est un asset embarqué dans l'application, pas une URL
     * distante : {@code EmotionalRadarVideo} sait lire un préfixe {@code assets/}.
     * La banque normée passera par Cloudinary et remplacera cette table.
     */
    /**
     * Ordre de passage des clips en démonstration. PROVISOIRE.
     *
     * <p>Sert avec {@link #DEMO_FOOTAGE_FIRST} : les scènes 1, 2 et 3 visent ces
     * émotions-là, dans cet ordre, pour qu'une démonstration montre les trois
     * vidéos à coup sûr. Sans cela, une session de 15 scènes tirées dans 45
     * émotions n'en montrerait aucune une fois sur trois.
     */
    public static final java.util.List<String> DEMO_FOOTAGE_ORDER =
        java.util.List.of("SADNESS", "ANXIETY", "LONELINESS");

    /**
     * Place les émotions filmées en tête de session. PROVISOIRE — DÉMO UNIQUEMENT.
     *
     * <p>Ce drapeau <b>casse volontairement l'équiprobabilité</b> des cibles :
     * un joueur qui connaît l'algorithme sait ce que visent les trois premières
     * scènes. C'est acceptable tant que le jeu ne mesure rien — la mesure est
     * déjà coupée par {@link #MEDIA_LIBRARY_READY} et {@link #SCORING_PROVISIONAL},
     * et aucune tentative n'est enregistrée. À repasser à {@code false} dès que
     * la banque de 135 vidéos est livrée : le tirage redevient alors uniforme
     * sans autre modification.
     */
    public static final boolean DEMO_FOOTAGE_FIRST = true; // PROVISOIRE — DÉMO

    public static final java.util.Map<String, DemoFootage> DEMO_FOOTAGE =
        java.util.Map.of(
            "SADNESS", new DemoFootage(
                "assets/games_demo/emotional_radar/phone_call.mp4", null),
            "ANXIETY", new DemoFootage(
                "assets/games_demo/emotional_radar/night_apartment.mp4", null),
            "LONELINESS", new DemoFootage(
                "assets/games_demo/emotional_radar/park_bench.mp4",
                "Un parc, en fin de journée."));

    /** Un clip de démonstration : son chemin, et sa légende si le stimulus l'exige. */
    public record DemoFootage(String mediaUrl, String contextualCaption) {
    }

    // ═══ Bandes d'interprétation de la reconnaissance émotionnelle (/100) ════
    // PROVISOIRE — alignées sur les autres jeux tant que le psychologue n'a pas tranché.

    public static String interpret(double normalized) {
        if (normalized < 40) return "Très faible";  // PROVISOIRE
        if (normalized < 60) return "Moyen faible";  // PROVISOIRE
        if (normalized < 75) return "Moyen";         // PROVISOIRE
        if (normalized < 90) return "Bon";           // PROVISOIRE
        return "Excellent";                          // PROVISOIRE
    }
}
