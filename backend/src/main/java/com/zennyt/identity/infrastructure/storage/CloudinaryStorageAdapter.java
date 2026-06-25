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
 * <p>Les CV sont des fichiers non-image (PDF/doc) : on les stocke en
 * {@code resource_type=raw} sous le dossier {@code zennyt/cv}. On conserve le
 * {@code public_id} retourné pour pouvoir remplacer ou supprimer le fichier.
 */
@Component
@RequiredArgsConstructor
public class CloudinaryStorageAdapter implements FileStoragePort {

    private static final String CV_FOLDER = "zennyt/cv";

    private final Cloudinary cloudinary;

    @Override
    public StoredFile upload(byte[] content, String filename, String contentType) {
        try {
            Map<?, ?> result = cloudinary.uploader().upload(content, ObjectUtils.asMap(
                "folder", CV_FOLDER,
                "resource_type", "raw",
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
    public void delete(String publicId) {
        if (publicId == null || publicId.isBlank()) {
            return;
        }
        try {
            cloudinary.uploader().destroy(publicId,
                ObjectUtils.asMap("resource_type", "raw"));
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de la suppression du fichier sur Cloudinary", e);
        }
    }
}
