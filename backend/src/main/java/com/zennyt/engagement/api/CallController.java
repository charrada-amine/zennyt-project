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
import java.util.UUID;

@RestController @RequestMapping("/api/v1/calls") @RequiredArgsConstructor
public class CallController {
    private final InitiateCallUseCase initiate;
    private final JoinCallUseCase join;
    private final EndCallUseCase end;
    @PostMapping("/start") @EngagementAuthenticated
    public ResponseEntity<CallResponse> start(@Valid @RequestBody CallInitiateRequest request, Principal principal) {
        return ResponseEntity.status(HttpStatus.CREATED).body(CallResponse.from(initiate.execute(actor(principal), request.conversationId(), request.type(), request.webrtcOffer())));
    }
    @PostMapping("/{callId}/join") @EngagementAuthenticated
    public CallResponse join(@PathVariable UUID callId, @Valid @RequestBody CallJoinRequest request, Principal principal) { return CallResponse.from(join.execute(actor(principal), callId, request.webrtcAnswer())); }
    @PostMapping("/{callId}/end") @EngagementAuthenticated
    public ResponseEntity<Void> end(@PathVariable UUID callId, Principal principal) { end.execute(actor(principal), callId); return ResponseEntity.noContent().build(); }
    private static UUID actor(Principal principal) { return UUID.fromString(principal.getName()); }
}
