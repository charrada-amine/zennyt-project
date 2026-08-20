package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.EngagementSupportDtos.*;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController @RequestMapping("/api/v1/help-chats") @RequiredArgsConstructor
public class HelpChatController {
    private final ListHelpChatsUseCase listChats;
    private final ListHelpMessagesUseCase listMessages;
    private final SendHelpMessageUseCase sendMessage;
    private final OpenHelpChatUseCase openChat;
    private final RateHelpChatUseCase rateChat;

    /** POST /api/v1/help-chats — Ouvrir une conversation d'aide */
    @PostMapping @EngagementAuthenticated
    public ResponseEntity<HelpChatResponse> open(@RequestBody(required = false) HelpChatOpenRequest request,
                                                 Principal principal) {
        String title = request == null ? null : request.title();
        String subtitle = request == null ? null : request.subtitle();
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(HelpChatResponse.from(openChat.execute(actor(principal), title, subtitle)));
    }

    /** POST /api/v1/help-chats/{id}/rating — Noter l'echange (Poor / OK / Great) */
    @PostMapping("/{helpChatId}/rating") @EngagementAuthenticated
    public HelpChatResponse rate(@PathVariable UUID helpChatId,
                                 @Valid @RequestBody HelpChatRatingRequest request,
                                 Principal principal) {
        return HelpChatResponse.from(
            rateChat.execute(actor(principal), helpChatId, request.rating(), request.comment()));
    }
    @GetMapping @EngagementAuthenticated
    public List<HelpChatResponse> list(Principal principal) { return listChats.execute(actor(principal)).stream().map(HelpChatResponse::from).toList(); }
    @GetMapping("/{helpChatId}/messages") @EngagementAuthenticated
    public List<HelpMessageResponse> messages(@PathVariable UUID helpChatId, Principal principal) { return listMessages.execute(actor(principal), helpChatId).stream().map(HelpMessageResponse::from).toList(); }
    @PostMapping("/{helpChatId}/messages") @EngagementAuthenticated
    public ResponseEntity<HelpMessageResponse> send(@PathVariable UUID helpChatId, @Valid @RequestBody HelpMessageRequest request, Principal principal) {
        return ResponseEntity.status(HttpStatus.CREATED).body(HelpMessageResponse.from(sendMessage.execute(actor(principal), helpChatId, request.text())));
    }
    private static UUID actor(Principal principal) { return UUID.fromString(principal.getName()); }
}
