package com.zennyt.games.api;

import com.zennyt.games.application.usecase.ManageGamesAdminUseCase;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/** Authenticated delivery endpoint for published, locally stored game assets. */
@RestController
@RequestMapping("/api/v1/games/assets")
public class GamesAssetController {
    private final ManageGamesAdminUseCase admin;

    public GamesAssetController(ManageGamesAdminUseCase admin) {
        this.admin = admin;
    }

    @GetMapping("/{assetId}")
    public ResponseEntity<byte[]> publishedAsset(@PathVariable UUID assetId) {
        ManageGamesAdminUseCase.AssetContent content = admin.publishedAssetContent(assetId);
        String mediaType = "PNG".equals(content.asset().mediaType())
            ? MediaType.IMAGE_PNG_VALUE : "image/svg+xml";
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(mediaType))
            .header("Cache-Control", "private, max-age=300")
            .body(content.bytes());
    }
}
