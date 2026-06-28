package com.zennyt.identity.infrastructure.storage;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.zennyt.identity.application.port.FileStoragePort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Map;

/**
 * Adaptateur Cloudinary du {@link FileStoragePort}.
 *
 * <p>Les CV sont des fichiers non-image (PDF/doc) : stockés en
 * {@code resource_type=raw}. Les avatars et logos sont des images
 * ({@code resource_type=image}). Le dossier et le type sont fournis par
 * l'appelant. On conserve le {@code public_id} retourné pour pouvoir remplacer
 * ou supprimer le fichier.
 */
@Component
@RequiredArgsConstructor
public class CloudinaryStorageAdapter implements FileStoragePort {

    private final Cloudinary cloudinary;

    @Override
    public StoredFile upload(byte[] content, String filename, String contentType,
                             String folder, ResourceType resourceType) {
        try {
            Map<?, ?> result = cloudinary.uploader().upload(content, ObjectUtils.asMap(
                "folder", folder,
                "resource_type", resourceTypeValue(resourceType),
                "use_filename", true,
                "unique_filename", true,
                "overwrite", false
            ));
            return new StoredFile(
                String.valueOf(result.get("secure_url")),
                String.valueOf(result.get("public_id")));
        } catch (IOException e) {
            throw new UncheckedIOException("Échec du téléversement du fichier vers Cloudinary", e);
        }
    }

    @Override
    public void delete(String publicId, ResourceType resourceType) {
        if (publicId == null || publicId.isBlank()) {
            return;
        }
        try {
            cloudinary.uploader().destroy(publicId,
                ObjectUtils.asMap("resource_type", resourceTypeValue(resourceType)));
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de la suppression du fichier sur Cloudinary", e);
        }
    }

    private static String resourceTypeValue(ResourceType resourceType) {
        return resourceType == ResourceType.IMAGE ? "image" : "raw";
    }
}
