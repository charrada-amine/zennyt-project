package com.zennyt.games.domain.model;

import com.zennyt.games.domain.model.AdminModels.ConfigurationKind;
import com.zennyt.games.domain.vo.GameType;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Single source of truth for administrable, non-scoring game controls.
 *
 * <p>The registry is intentionally limited to availability, accessibility and
 * presentation. Validated score constants remain in their dedicated protected
 * configuration classes and can never be addressed through this API.
 */
public final class AdminConfigurationSchemaRegistry {
    private AdminConfigurationSchemaRegistry() {}

    public enum ValueType { BOOLEAN, INTEGER, ENUM }

    public record Field(String key, String label, String description,
                        ValueType valueType, boolean required, Object defaultValue,
                        Integer minimum, Integer maximum, List<String> options) {
        public Field {
            Objects.requireNonNull(key);
            Objects.requireNonNull(label);
            Objects.requireNonNull(description);
            Objects.requireNonNull(valueType);
            Objects.requireNonNull(defaultValue);
            options = List.copyOf(options == null ? List.of() : options);
        }
    }

    public record Schema(GameType gameType, ConfigurationKind kind, List<Field> fields) {
        public Schema {
            Objects.requireNonNull(gameType);
            Objects.requireNonNull(kind);
            fields = List.copyOf(fields);
            if (fields.isEmpty()) throw new IllegalArgumentException("Un schéma doit exposer au moins un contrôle");
        }

        public Map<String, Object> defaultValues() {
            Map<String, Object> defaults = new LinkedHashMap<>();
            fields.forEach(field -> defaults.put(field.key(), field.defaultValue()));
            return Collections.unmodifiableMap(defaults);
        }
    }

    private static final Field SESSION_ENABLED = bool(
        "sessionEnabled", "Nouvelles sessions",
        "Autorise le démarrage de nouvelles parties. Les parties déjà ouvertes restent inchangées.", true);
    private static final Field REDUCED_MOTION = bool(
        "reducedMotionDefault", "Mouvements réduits par défaut",
        "Réduit les transitions décoratives sans modifier le protocole ni les temps mesurés.", false);
    private static final Field SCENE_COUNT = integer(
        "sceneCount", "Scènes par session",
        "Nombre de scènes Emotional Radar sélectionnées dans la banque publiée.", 3, 1, 15);
    private static final Field ORDER_MODE = enumeration(
        "orderMode", "Ordre des scènes",
        "Conserve l'ordre éditorial ou produit un mélange déterministe propre à la session.",
        "SEQUENTIAL", List.of("SEQUENTIAL", "SHUFFLED"));
    private static final Field HELP_ENABLED = bool(
        "helpEnabled", "Aide et règles",
        "Affiche l'accès aux règles pendant la partie.", true);
    private static final Field ANSWER_FEEDBACK = bool(
        "answerFeedback", "Feedback après réponse",
        "Affiche le retour pédagogique après chaque scène, sans révéler la clé avant validation.", true);
    private static final Field TRANSITION_DURATION = integer(
        "transitionDurationMs", "Transition entre scènes",
        "Durée de la transition de présentation, en millisecondes.", 900, 0, 5_000);

    private static final List<Schema> SCHEMAS = buildSchemas();

    public static List<Schema> all() {
        return SCHEMAS;
    }

    /** Resolve optional fields once at session creation, not on every read. */
    public static Map<String, Object> effectiveValues(String gameType, ConfigurationKind kind,
                                                     Map<String, Object> published) {
        Map<String, Object> resolved = new LinkedHashMap<>(schema(gameType, kind).defaultValues());
        resolved.putAll(published);
        validate(gameType, kind, resolved);
        return Collections.unmodifiableMap(resolved);
    }

    public static Schema schema(String gameType, ConfigurationKind kind) {
        GameType parsed = parseGameType(gameType);
        return SCHEMAS.stream()
            .filter(schema -> schema.gameType() == parsed && schema.kind() == kind)
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException(
                "Aucun schéma administrable pour " + parsed + " / " + kind));
    }

    public static void validate(String gameType, ConfigurationKind kind,
                                Map<String, Object> values) {
        Objects.requireNonNull(kind, "kind");
        Objects.requireNonNull(values, "values");
        Schema schema = schema(gameType, kind);
        Set<String> allowed = schema.fields().stream().map(Field::key)
            .collect(java.util.stream.Collectors.toUnmodifiableSet());
        List<String> unknown = values.keySet().stream().filter(key -> !allowed.contains(key)).sorted().toList();
        if (!unknown.isEmpty()) {
            throw new IllegalArgumentException("Contrôles inconnus ou protégés : " + String.join(", ", unknown));
        }
        for (Field field : schema.fields()) {
            if (!values.containsKey(field.key())) {
                if (field.required()) throw new IllegalArgumentException("Contrôle obligatoire manquant : " + field.key());
                continue;
            }
            validateValue(field, values.get(field.key()));
        }
    }

    private static void validateValue(Field field, Object value) {
        if (value == null) throw new IllegalArgumentException("Valeur obligatoire : " + field.key());
        switch (field.valueType()) {
            case BOOLEAN -> {
                if (!(value instanceof Boolean)) invalidType(field);
            }
            case INTEGER -> {
                if (!(value instanceof Number number)
                        || number.doubleValue() != Math.rint(number.doubleValue())) invalidType(field);
                long integer = ((Number) value).longValue();
                if (integer < field.minimum() || integer > field.maximum()) {
                    throw new IllegalArgumentException(field.key() + " doit être compris entre "
                        + field.minimum() + " et " + field.maximum());
                }
            }
            case ENUM -> {
                if (!(value instanceof String text) || !field.options().contains(text)) {
                    throw new IllegalArgumentException(field.key() + " doit valoir l'une de ces options : "
                        + String.join(", ", field.options()));
                }
            }
        }
    }

    private static void invalidType(Field field) {
        throw new IllegalArgumentException("Type invalide pour " + field.key() + " (" + field.valueType() + ")");
    }

    private static GameType parseGameType(String gameType) {
        try {
            return GameType.valueOf(Objects.requireNonNull(gameType, "gameType").trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException("GameType non administrable : " + gameType, exception);
        }
    }

    private static List<Schema> buildSchemas() {
        List<Schema> schemas = new ArrayList<>();
        for (GameType gameType : GameType.values()) {
            List<Field> settings = new ArrayList<>(gameType == GameType.EMOTIONAL_REGULATION
                ? List.of(SESSION_ENABLED, SCENE_COUNT, ORDER_MODE, HELP_ENABLED)
                : List.of(SESSION_ENABLED));
            // PROVISOIRE — bornes d'exploitation à valider. Defaults mirror
            // mobile GamePresentationTiming; score constants are never changed.
            settings.addAll(switch (gameType) {
                case MEMORY_QUEST -> List.of(
                    timing("memoryDigitVisibleMs", "Chiffres · temps d'observation", "Durée de visibilité de chaque chiffre avant le rappel.", 900, 300, 3000),
                    timing("memoryDigitGapMs", "Chiffres · intervalle", "Écran vide entre deux chiffres. La saisie reste verrouillée.", 1000, 200, 3000),
                    timing("memoryManipulationStepMs", "Images · rythme des échanges", "Durée de chaque étape de mise en évidence et d'échange d'objets.", 750, 200, 3000),
                    timing("memoryRetentionMs", "Images · pause avant rappel", "Temps de consolidation après les échanges, avant la restitution.", 3000, 0, 10000));
                case PLANIFIK -> List.of(timing("puzzlePlaybackStepMs", "Predictive Puzzle · vitesse de lecture", "Durée de chaque mouvement lors de l'exécution du plan. Les essais et le barème ne changent pas.", 420, 150, 2000));
                case MOVE_FAST -> List.of(timing("responseFeedbackMs", "Move Fast · feedback entre essais", "Temps d'affichage du retour avant l'avion suivant. Le budget de session reste inchangé.", 650, 200, 2000));
                case EMOTIONAL_REGULATION -> List.of(
                    timing("reflectiveThinkingTimeMs", "Reflective Pause · temps de réflexion", "Délai avant validation. Ne peut pas descendre sous les 3 s du protocole ; le seuil du barème reste 3 s.", 3000, 3000, 15000),
                    timing("reflectiveTransitionMs", "Reflective Pause · transition", "Durée de la confirmation entre deux moments. Ignorée en mouvements réduits.", 700, 0, 5000));
                default -> List.of();
            });
            List<Field> modifiers = gameType == GameType.EMOTIONAL_REGULATION
                ? List.of(REDUCED_MOTION, ANSWER_FEEDBACK, TRANSITION_DURATION)
                : List.of(REDUCED_MOTION);
            schemas.add(new Schema(gameType, ConfigurationKind.SETTINGS, settings));
            schemas.add(new Schema(gameType, ConfigurationKind.MODIFIERS, modifiers));
        }
        return List.copyOf(schemas);
    }

    private static Field bool(String key, String label, String description, boolean defaultValue) {
        return new Field(key, label, description, ValueType.BOOLEAN, true, defaultValue,
            null, null, List.of());
    }

    private static Field timing(String key, String label, String description,
                                int defaultValue, int minimum, int maximum) {
        // Optional for compatibility with immutable pre-1.8 snapshots/publications.
        return new Field(key, label, description, ValueType.INTEGER, false, defaultValue,
            minimum, maximum, List.of());
    }

    private static Field integer(String key, String label, String description,
                                 int defaultValue, int minimum, int maximum) {
        return new Field(key, label, description, ValueType.INTEGER, true, defaultValue,
            minimum, maximum, List.of());
    }

    private static Field enumeration(String key, String label, String description,
                                     String defaultValue, List<String> options) {
        return new Field(key, label, description, ValueType.ENUM, true, defaultValue,
            null, null, options);
    }
}
