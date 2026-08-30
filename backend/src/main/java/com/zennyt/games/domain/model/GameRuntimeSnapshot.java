package com.zennyt.games.domain.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Immutable, non-scoring runtime configuration captured when a session starts. */
public record GameRuntimeSnapshot(
        UUID bankId,
        String bankCode,
        Integer bankVersion,
        String bankContentType,
        Integer settingsVersion,
        Integer modifiersVersion,
        Map<String, Object> settings,
        Map<String, Object> modifiers) {

    public GameRuntimeSnapshot {
        settings = immutableMap(settings);
        modifiers = immutableMap(modifiers);
    }

    public GameRuntimeSnapshot(Integer settingsVersion, Integer modifiersVersion,
                               Map<String, Object> settings,
                               Map<String, Object> modifiers) {
        this(null, null, null, null, settingsVersion, modifiersVersion, settings, modifiers);
    }

    public static GameRuntimeSnapshot empty() {
        return new GameRuntimeSnapshot(null, null, null, null,
            null, null, Map.of(), Map.of());
    }

    public int settingInt(String key, int fallback, int minimum, int maximum) {
        Object value = settings.get(key);
        if (!(value instanceof Number number)) return fallback;
        return Math.max(minimum, Math.min(maximum, number.intValue()));
    }

    public String settingString(String key, String fallback) {
        Object value = settings.get(key);
        return value instanceof String text && !text.isBlank() ? text : fallback;
    }

    private static Map<String, Object> immutableMap(Map<String, Object> source) {
        if (source == null || source.isEmpty()) return Map.of();
        Map<String, Object> copy = new LinkedHashMap<>();
        source.forEach((key, value) -> copy.put(key, immutableValue(value)));
        return Collections.unmodifiableMap(copy);
    }

    private static Object immutableValue(Object value) {
        if (value instanceof Map<?, ?> nested) {
            Map<String, Object> copy = new LinkedHashMap<>();
            nested.forEach((key, item) -> {
                if (!(key instanceof String text)) {
                    throw new IllegalArgumentException("Clé JSON runtime non textuelle");
                }
                copy.put(text, immutableValue(item));
            });
            return Collections.unmodifiableMap(copy);
        }
        if (value instanceof List<?> nested) {
            List<Object> copy = new ArrayList<>(nested.size());
            nested.forEach(item -> copy.add(immutableValue(item)));
            return Collections.unmodifiableList(copy);
        }
        return value;
    }
}
