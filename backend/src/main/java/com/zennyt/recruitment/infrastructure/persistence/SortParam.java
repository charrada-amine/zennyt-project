package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Sort;

import java.util.Set;

/**
 * Parse un paramètre de tri client ({@code "champ,direction"}, ex.
 * {@code "postedAt,desc"}) en {@link Sort} JPA — jamais le champ brut du
 * client sans whitelist, pour éviter un {@code PropertyReferenceException}
 * sur un nom de champ inconnu ou non désiré.
 */
final class SortParam {
    private SortParam() {}

    static Sort parse(String sort, Set<String> allowedFields, Sort fallback) {
        if (sort == null || sort.isBlank()) return fallback;
        String[] parts = sort.split(",", 2);
        String field = parts[0].trim();
        if (!allowedFields.contains(field)) return fallback;
        Sort.Direction direction = parts.length > 1 && "desc".equalsIgnoreCase(parts[1].trim())
            ? Sort.Direction.DESC : Sort.Direction.ASC;
        return Sort.by(direction, field);
    }
}
