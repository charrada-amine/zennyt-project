package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.port.EngagementMediaStoragePort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service @RequiredArgsConstructor
public class UploadEngagementMediaUseCase {
    private static final long MAX_BYTES = 5L * 1024 * 1024;
    private final EngagementMediaStoragePort storage;
    public EngagementMediaStoragePort.StoredMedia execute(
            byte[] content, String filename, String contentType) {
        if (content == null || content.length == 0) throw new IllegalArgumentException("Fichier vide");
        if (content.length > MAX_BYTES) throw new IllegalArgumentException("Fichier supérieur à 5 Mo");
        var type = resourceType(contentType);
        return storage.upload(content, filename == null ? "media" : filename, contentType, type);
    }
    private EngagementMediaStoragePort.ResourceType resourceType(String contentType) {
        if (contentType == null) throw new IllegalArgumentException("Type de fichier obligatoire");
        if (contentType.startsWith("image/")) return EngagementMediaStoragePort.ResourceType.IMAGE;
        if (contentType.startsWith("video/")) return EngagementMediaStoragePort.ResourceType.VIDEO;
        if (contentType.equals("application/pdf")) return EngagementMediaStoragePort.ResourceType.RAW;
        throw new IllegalArgumentException("Type de média non supporté");
    }
}
