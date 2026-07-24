package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.PushDeviceRegistrationRequest;
import com.zennyt.engagement.api.dto.RealtimeConnectionResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.port.RealtimeNegotiationPort;
import com.zennyt.engagement.application.usecase.RegisterPushDeviceUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/realtime")
@RequiredArgsConstructor
public class RealtimeController {
    private final RealtimeNegotiationPort realtime;
    private final RegisterPushDeviceUseCase registerPushDevice;

    @PostMapping("/negotiate")
    @EngagementAuthenticated
    public ResponseEntity<RealtimeConnectionResponse> negotiate(Principal principal) {
        return ResponseEntity.ok(RealtimeConnectionResponse.from(
            realtime.negotiate(actor(principal))));
    }

    @PostMapping("/devices")
    @EngagementAuthenticated
    public ResponseEntity<Void> register(
            @Valid @RequestBody PushDeviceRegistrationRequest request,
            Principal principal) {
        registerPushDevice.execute(actor(principal), request.token(),
            request.platform(), request.deviceName());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    private static UUID actor(Principal principal) {
        return UUID.fromString(principal.getName());
    }
}
