package com.zennyt.games.infrastructure.storage;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.zennyt.games.application.port.GamesMediaStoragePort;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
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

    private final Cloudinary cloudinary;

    public CloudinaryGamesMediaStorageAdapter(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    @Override
    public StoredMedia upload(byte[] content, String filename, ResourceType resourceType) {
        String type = resourceType.name().toLowerCase();
        try {
            Map<?, ?> result = cloudinary.uploader().upload(content, ObjectUtils.asMap(
                "folder", "zennyt/games/emotional-radar",
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
                "Échec du téléversement du média de scène Emotional Radar", exception);
        }
    }
}
