package com.zennyt.identity.domain.model;

import java.time.Instant;

public record Skill(Long id, String name, SkillType type, Integer level,
                    Instant createdAt, Instant updatedAt) {
    public Skill {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Le nom de la compétence est obligatoire");
        }
        name = name.trim();
        if (level != null && (level < 1 || level > 5)) {
            throw new IllegalArgumentException("Le niveau doit être compris entre 1 et 5");
        }
    }

    public static Skill create(String name, SkillType type, Integer level) {
        Instant now = Instant.now();
        return new Skill(null, name, type, level, now, now);
    }
}
