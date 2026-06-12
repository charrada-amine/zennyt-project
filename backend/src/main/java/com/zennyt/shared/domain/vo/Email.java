package com.zennyt.shared.domain.vo;

import java.util.regex.Pattern;

/**
 * Value Object Email : immuable, auto-validant.
 *
 * <p>Exemple de la philosophie DDD : on ne fait pas circuler des String nues,
 * on encapsule les règles d'invariance dans un type dédié. Un Email mal formé
 * ne peut jamais exister dans le domaine.
 */
public record Email(String value) {

    private static final Pattern PATTERN =
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    public Email {
        if (value == null || !PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException("Email invalide : " + value);
        }
        value = value.toLowerCase();
    }

    @Override
    public String toString() {
        return value;
    }
}
