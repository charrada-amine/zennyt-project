package com.zennyt.games.infrastructure.storage;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.zennyt.games.application.port.GamesMediaStoragePort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;

/**
 * Adaptateur Cloudinary du port média de {@code games}.
 *
 * <p>Copie fidèle du patron d'{@code engagement} : même bean {@code Cloudinary}
 * partagé, mais un dossier distant dédié ({@code zennyt/games}) pour que les
 * médias des jeux restent identifiables et purgeables indépendamment.
 *
 * <p>Cloudinary gère nativement le transcodage et la diffusion des vidéos : c'est
 * ce qui rend le support vidéo des scènes viable sans dépendance supplémentaire.
 */
@Component
public class CloudinaryGamesMediaStorageAdapter implements GamesMediaStoragePort {
    private static final Path LOCAL_ASSET_DIRECTORY = Path.of("/tmp/zennyt-games-assets");

    private final Cloudinary cloudinary;
    private final boolean localDevelopmentStorage;

    public CloudinaryGamesMediaStorageAdapter(
            Cloudinary cloudinary,
            @Value("${spring.profiles.active:}") String activeProfiles,
            @Value("${cloudinary.cloud-name:}") String cloudName,
            @Value("${cloudinary.api-key:}") String apiKey,
            @Value("${cloudinary.api-secret:}") String apiSecret) {
        this.cloudinary = cloudinary;
        this.localDevelopmentStorage = activeProfiles.contains("dev")
            && (cloudName.isBlank() || apiKey.isBlank() || apiSecret.isBlank());
    }

    @Override
    public StoredMedia upload(byte[] content, String filename, ResourceType resourceType) {
        return upload(content, filename, resourceType, "emotional-radar");
    }

    @Override
    public StoredMedia upload(byte[] content, String filename, ResourceType resourceType,
                              String subfolder) {
        if (localDevelopmentStorage) return uploadLocally(content, filename, resourceType);
        String type = resourceType.name().toLowerCase();
        try {
            Map<?, ?> result = cloudinary.uploader().upload(content, ObjectUtils.asMap(
                "folder", "zennyt/games/" + subfolder,
                "resource_type", type,
                "public_id", UUID.randomUUID() + "_" + filename,
                "overwrite", false,
                "access_mode", "public"));
            return new StoredMedia(
                String.valueOf(result.get("secure_url")),
                String.valueOf(result.get("public_id")),
                type);
        } catch (IOException exception) {
            throw new UncheckedIOException(
                "Échec du téléversement du média games", exception);
        }
    }

    @Override
    public void delete(String publicId, ResourceType resourceType) {
        if (publicId.startsWith("local/")) {
            try {
                Files.deleteIfExists(localPath(publicId));
                return;
            } catch (IOException exception) {
                throw new UncheckedIOException("Échec de la suppression du média games local", exception);
            }
        }
        try {
            cloudinary.uploader().destroy(publicId, ObjectUtils.asMap(
                "resource_type", resourceType.name().toLowerCase(),
                "invalidate", true));
        } catch (IOException exception) {
            throw new UncheckedIOException("Échec de la suppression du média games", exception);
        }
    }

    @Override
    public byte[] read(String publicId) {
        if (!publicId.startsWith("local/")) {
            throw new IllegalArgumentException("Le média n'appartient pas au stockage local");
        }
        try {
            return Files.readAllBytes(localPath(publicId));
        } catch (IOException exception) {
            throw new UncheckedIOException("Échec de lecture du média games local", exception);
        }
    }

    private StoredMedia uploadLocally(byte[] content, String filename, ResourceType resourceType) {
        String extension = filename.toLowerCase().endsWith(".svg") ? ".svg" : ".png";
        String storedFilename = UUID.randomUUID() + extension;
        try {
            Files.createDirectories(LOCAL_ASSET_DIRECTORY);
            Files.write(LOCAL_ASSET_DIRECTORY.resolve(storedFilename), content);
            return new StoredMedia("local://" + storedFilename, "local/" + storedFilename,
                resourceType.name().toLowerCase());
        } catch (IOException exception) {
            throw new UncheckedIOException("Échec du stockage local du média games", exception);
        }
    }

    private static Path localPath(String publicId) {
        String storedFilename = publicId.substring("local/".length());
        if (!storedFilename.equals(Path.of(storedFilename).getFileName().toString())) {
            throw new IllegalArgumentException("Identifiant de média local invalide");
        }
        return LOCAL_ASSET_DIRECTORY.resolve(storedFilename);
    }
}
