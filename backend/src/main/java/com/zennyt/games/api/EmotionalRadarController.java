package com.zennyt.games.api;

import com.zennyt.games.api.dto.EmotionalRadarDtos.AnswerRequest;
import com.zennyt.games.api.dto.EmotionalRadarDtos.FeedbackResponse;
import com.zennyt.games.api.dto.EmotionalRadarDtos.SceneListResponse;
import com.zennyt.games.api.dto.EmotionalRadarDtos.SceneResponse;
import com.zennyt.games.application.usecase.AnswerEmotionalRadarSceneUseCase;
import com.zennyt.games.application.usecase.GetEmotionalRadarScenesUseCase;
import com.zennyt.games.application.usecase.UploadEmotionalRadarMediaUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

/**
 * Contrôleur REST d'« Emotional Radar ».
 *
 * <p>Couche fine, sans logique métier. Trois responsabilités :
 * <ol>
 *   <li>servir les scènes <b>expurgées de leur réponse</b> ;</li>
 *   <li>corriger une scène et renvoyer son feedback ;</li>
 *   <li>rattacher un média (image/vidéo) à une scène.</li>
 * </ol>
 *
 * <p>Le contenu (texte, image, vidéo) est stocké côté backend : c'est le premier
 * jeu du module dont le matériel n'est pas embarqué dans l'application.
 */
@RestController
@RequestMapping("/api/v1/games")
public class EmotionalRadarController {

    private final GetEmotionalRadarScenesUseCase getScenes;
    private final AnswerEmotionalRadarSceneUseCase answerScene;
    private final UploadEmotionalRadarMediaUseCase uploadMedia;

    public EmotionalRadarController(GetEmotionalRadarScenesUseCase getScenes,
                                    AnswerEmotionalRadarSceneUseCase answerScene,
                                    UploadEmotionalRadarMediaUseCase uploadMedia) {
        this.getScenes = getScenes;
        this.answerScene = answerScene;
        this.uploadMedia = uploadMedia;
    }

    /** Scènes + taxonomie émotion → nuances, sans aucune réponse attendue. */
    @GetMapping("/sessions/{sessionId}/emotional-radar/scenes")
    public ResponseEntity<SceneListResponse> scenes(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(SceneListResponse.from(getScenes.execute(sessionId)));
    }

    /**
     * Valide la réponse d'une scène. Le serveur note, persiste, puis révèle la
     * correction — jamais l'inverse.
     */
    @PostMapping("/sessions/{sessionId}/emotional-radar/scenes/{sceneId}/answers")
    public ResponseEntity<FeedbackResponse> answer(
            @PathVariable UUID sessionId,
            @PathVariable UUID sceneId,
            @Valid @RequestBody AnswerRequest request) {

        AnswerEmotionalRadarSceneUseCase.Result result = answerScene.execute(
            sessionId, sceneId,
            request.selectedEmotion(),
            request.selectedNuance(),
            request.selectedIntensity());

        return ResponseEntity.ok(FeedbackResponse.from(result));
    }

    /**
     * Téléverse le média d'une scène.
     *
     * <p>Opération éditoriale réservée au rôle {@code ADMIN}.
     */
    @PostMapping(value = "/emotional-radar/scenes/{sceneId}/media",
                 consumes = "multipart/form-data")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SceneResponse> uploadMedia(
            @PathVariable UUID sceneId,
            @RequestPart("file") MultipartFile file,
            @RequestParam(required = false) String altText,
            @RequestParam(required = false) String transcript) throws IOException {

        var scene = uploadMedia.execute(
            sceneId, file.getBytes(), file.getOriginalFilename(), altText, transcript);

        return ResponseEntity.status(HttpStatus.CREATED).body(SceneResponse.from(scene));
    }
}
