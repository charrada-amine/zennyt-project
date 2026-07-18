package com.zennyt.engagement.domain.model;

import java.util.List;

/** Résultat paginé Java pur, indépendant de Spring Data. */
public record PageSlice<T>(List<T> content, int page, int size, long totalElements) {
    public PageSlice {
        content = List.copyOf(content);
        if (page < 0 || size < 1 || totalElements < 0) {
            throw new IllegalArgumentException("Pagination invalide");
        }
    }

    public int totalPages() {
        return totalElements == 0 ? 0 : (int) Math.ceil((double) totalElements / size);
    }
}
