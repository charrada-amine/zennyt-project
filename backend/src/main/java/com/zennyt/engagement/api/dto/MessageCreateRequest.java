package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.vo.MessageContentType;
import jakarta.validation.constraints.NotBlank;

public record MessageCreateRequest(@NotBlank String content,
                                   ClientMessageContentType contentType,
                                   String attachmentUrl) {
    public MessageContentType domainContentType() {
        return contentType == null ? MessageContentType.TEXT
            : MessageContentType.valueOf(contentType.name());
    }

    public enum ClientMessageContentType { TEXT, IMAGE, FILE }
}
