package com.zennyt.recruitment.api.dto;

import java.util.List;

/** Enveloppe de pagination — {@code content} + {@code page} imbriqué, forme du contrat OpenAPI. */
public record PageResponse<T>(List<T> content, PageMeta page) {
    public static <T> PageResponse<T> of(List<T> content, int page, int size, long totalElements) {
        return new PageResponse<>(content, PageMeta.of(page, size, totalElements));
    }
}
