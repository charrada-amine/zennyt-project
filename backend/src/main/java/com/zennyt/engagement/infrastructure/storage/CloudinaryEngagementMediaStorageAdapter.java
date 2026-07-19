package com.zennyt.engagement.infrastructure.storage;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.zennyt.engagement.application.port.EngagementMediaStoragePort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Map;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class CloudinaryEngagementMediaStorageAdapter implements EngagementMediaStoragePort {
    private final Cloudinary cloudinary;

    @Override
    public StoredMedia upload(byte[] content, String filename, String contentType, ResourceType resourceType) {
        String type = resourceType.name().toLowerCase();
        try {
            Map<?, ?> result = cloudinary.uploader().upload(content, ObjectUtils.asMap(
                "folder", "zennyt/engagement",
                "resource_type", type,
                "public_id", UUID.randomUUID() + "_" + filename,
                "overwrite", false,
                "access_mode", "public"));
            return new StoredMedia(String.valueOf(result.get("secure_url")),
                String.valueOf(result.get("public_id")), type);
        } catch (IOException exception) {
            throw new UncheckedIOException("Échec du téléversement du média Engagement", exception);
        }
    }
}
