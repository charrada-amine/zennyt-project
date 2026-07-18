package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.ConversationCreateRequest;
import com.zennyt.engagement.api.dto.ConversationPageResponse;
import com.zennyt.engagement.api.dto.ConversationResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.ListConversationsUseCase;
import com.zennyt.engagement.application.usecase.EnsureConversationUseCase;
import com.zennyt.engagement.application.ActorDirectory;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/conversations")
@RequiredArgsConstructor
public class ConversationController {
    private final ListConversationsUseCase listConversations;
    private final EnsureConversationUseCase ensureConversation;
    private final ActorDirectory actors;

    @PostMapping
    @EngagementAuthenticated
    public ResponseEntity<ConversationResponse> create(
            @Valid @RequestBody ConversationCreateRequest request, Principal principal) {
        UUID actorId = UUID.fromString(principal.getName());
        EnsureConversationUseCase.Result result = ensureConversation.execute(actorId, request.applicationId());
        HttpStatus status = result.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status)
            .body(ConversationResponse.from(result.conversation(), actorId, actors));
    }

    @GetMapping
    @EngagementAuthenticated
    public ResponseEntity<ConversationPageResponse> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID actorId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(ConversationPageResponse.from(
            listConversations.execute(actorId, page, size), actorId, actors));
    }
}
