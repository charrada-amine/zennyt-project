package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.MessageCreateRequest;
import com.zennyt.engagement.api.dto.MessageResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.ListMessagesUseCase;
import com.zennyt.engagement.application.usecase.MarkConversationAsReadUseCase;
import com.zennyt.engagement.application.usecase.SendMessageUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/conversations/{conversationId}")
@RequiredArgsConstructor
public class MessageController {
    private final ListMessagesUseCase listMessages;
    private final SendMessageUseCase sendMessage;
    private final MarkConversationAsReadUseCase markAsRead;

    @GetMapping("/messages")
    @EngagementAuthenticated
    public ResponseEntity<List<MessageResponse>> list(
            @PathVariable UUID conversationId,
            @RequestParam(required = false) UUID before,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        return ResponseEntity.ok(listMessages.execute(actor(principal), conversationId, before, size)
            .stream().map(MessageResponse::from).toList());
    }

    @PostMapping("/messages")
    @EngagementAuthenticated
    public ResponseEntity<MessageResponse> send(
            @PathVariable UUID conversationId,
            @Valid @RequestBody MessageCreateRequest request,
            Principal principal) {
        var message = sendMessage.execute(actor(principal), conversationId, request.content(),
            request.domainContentType(), request.attachmentUrl());
        return ResponseEntity.status(HttpStatus.CREATED).body(MessageResponse.from(message));
    }

    @PostMapping("/read")
    @EngagementAuthenticated
    public ResponseEntity<Void> read(@PathVariable UUID conversationId, Principal principal) {
        markAsRead.execute(actor(principal), conversationId);
        return ResponseEntity.noContent().build();
    }

    private static UUID actor(Principal principal) {
        return UUID.fromString(principal.getName());
    }
}
