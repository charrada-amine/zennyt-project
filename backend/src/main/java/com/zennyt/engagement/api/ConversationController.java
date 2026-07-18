package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.ConversationPageResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.ListConversationsUseCase;
import com.zennyt.engagement.application.usecase.CreateConversationUseCase;
import com.zennyt.engagement.application.ActorDirectory;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/conversations")
@RequiredArgsConstructor
public class ConversationController {
    private final ListConversationsUseCase listConversations;
    private final CreateConversationUseCase createConversation;
    private final ActorDirectory actors;

    @PostMapping
    @EngagementAuthenticated
    public ResponseEntity<com.zennyt.engagement.api.dto.ConversationResponse> create(
            @RequestBody java.util.Map<String, UUID> request, Principal principal) {
        UUID actorId = UUID.fromString(principal.getName());
        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED)
            .body(com.zennyt.engagement.api.dto.ConversationResponse.from(
                createConversation.execute(actorId, request.get("applicationId")), actorId, actors));
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
