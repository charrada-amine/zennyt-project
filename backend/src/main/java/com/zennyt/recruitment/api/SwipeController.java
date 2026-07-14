package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.SwipeRequest;
import com.zennyt.recruitment.api.dto.SwipeResponse;
import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.application.usecase.RecordSwipeUseCase;
import com.zennyt.recruitment.application.usecase.UndoSwipeUseCase;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/** Contrôleur REST pour les swipes. */
@RestController
@RequestMapping("/api/v1/swipes")
public class SwipeController {

    private final RecordSwipeUseCase recordSwipeUseCase;
    private final UndoSwipeUseCase undoSwipeUseCase;
    private final SwipeRepository swipeRepository;

    public SwipeController(RecordSwipeUseCase recordSwipeUseCase,
                           UndoSwipeUseCase undoSwipeUseCase,
                           SwipeRepository swipeRepository) {
        this.recordSwipeUseCase = recordSwipeUseCase;
        this.undoSwipeUseCase = undoSwipeUseCase;
        this.swipeRepository = swipeRepository;
    }

    /** POST /api/v1/swipes — Enregistrer un swipe (upsert : re-swiper met à jour) */
    @PostMapping
    @PreAuthorize("(hasAnyRole('CANDIDATE', 'STUDENT') and "
        + "@recruitmentActorPolicy.activeWithAnyRole(authentication.name, 'CANDIDATE', 'STUDENT') "
        + "and #req.targetType() == 'JOB_OFFER') or (hasRole('RECRUITER') and "
        + "@recruitmentActorPolicy.activeWithRole(authentication.name, 'RECRUITER') "
        + "and #req.targetType() == 'CANDIDATE')")
    public ResponseEntity<SwipeResponse> swipe(@RequestBody SwipeRequest req, Principal principal) {
        UUID actorId = UUID.fromString(principal.getName());
        var result = recordSwipeUseCase.execute(
            actorId, req.targetId(), req.targetType(), req.jobOfferId(), req.resolvedDirection());
        return ResponseEntity.status(HttpStatus.CREATED).body(SwipeResponse.from(result));
    }

    /**
     * DELETE /api/v1/swipes/{swipeId}?matchId= — Annuler un swipe (undo).
     *
     * <p>Idempotent : 204 même si le swipe a déjà été supprimé. Le match associé
     * est supprimé dans la même transaction.
     */
    @DeleteMapping("/{swipeId}")
    @Authenticated
    public ResponseEntity<Void> undo(@PathVariable UUID swipeId,
                                     Principal principal) {
        undoSwipeUseCase.execute(swipeId, UUID.fromString(principal.getName()));
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/v1/swipes/targets — Ids des cibles déjà swipées par un utilisateur.
     *
     * <p>Sert au frontend à exclure les cartes déjà swipées du deck sans
     * télécharger les objets swipe complets. {@code jobOfferId} scope la
     * recherche à une offre (usage recruteur).
     */
    @GetMapping("/targets")
    @Authenticated
    public ResponseEntity<List<UUID>> targets(
            @RequestParam(required = false) UUID jobOfferId,
            Principal principal) {
        UUID actorId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(swipeRepository.findTargetIdsByActorId(actorId, jobOfferId));
    }
}
