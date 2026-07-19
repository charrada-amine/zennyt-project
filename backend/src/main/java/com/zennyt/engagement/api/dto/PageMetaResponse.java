package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.model.PageSlice;

public record PageMetaResponse(int page, int size, long totalElements, int totalPages,
                               boolean first, boolean last) {
    public static PageMetaResponse from(PageSlice<?> slice) {
        int totalPages = slice.totalPages();
        return new PageMetaResponse(slice.page(), slice.size(), slice.totalElements(), totalPages,
            slice.page() == 0, totalPages == 0 || slice.page() >= totalPages - 1);
    }
}
