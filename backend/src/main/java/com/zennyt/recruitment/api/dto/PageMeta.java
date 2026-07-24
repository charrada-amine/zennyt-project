package com.zennyt.recruitment.api.dto;

/** Métadonnées de pagination — forme partagée par toutes les enveloppes de liste paginée. */
public record PageMeta(int page, int size, long totalElements, int totalPages) {
    public static PageMeta of(int page, int size, long totalElements) {
        int safeSize = Math.max(1, size);
        int totalPages = (int) Math.ceil(totalElements / (double) safeSize);
        return new PageMeta(Math.max(0, page), safeSize, totalElements, totalPages);
    }
}
