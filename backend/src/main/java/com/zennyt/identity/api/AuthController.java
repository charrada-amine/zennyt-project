package com.zennyt.identity.api;

import com.zennyt.identity.application.AuthService;
import com.zennyt.identity.application.IdentityService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import static com.zennyt.identity.api.IdentityDtos.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService auth;
    private final IdentityService identity;

    public AuthController(AuthService auth, IdentityService identity) {
        this.auth = auth;
        this.identity = identity;
    }

    @PostMapping("/register")
    public ResponseEntity<TokenResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(TokenResponse.from(auth.register(
            request.firstName(), request.lastName(), request.email(), request.phoneNumber(),
            request.password(), request.role(), request.city(), request.country(), request.address(),
            request.termsAccepted())));
    }

    @PostMapping("/login")
    public TokenResponse login(@Valid @RequestBody LoginRequest request) {
        return TokenResponse.from(auth.login(request.email(), request.password()));
    }

    @PostMapping("/social")
    public TokenResponse socialLogin(@Valid @RequestBody SocialLoginRequest request) {
        return TokenResponse.from(auth.socialLogin(
            request.provider(), request.idToken(), request.firstName(), request.lastName(),
            request.role(), request.termsAccepted()));
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return TokenResponse.from(auth.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest request) {
        auth.logout(request.refreshToken());
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal Jwt jwt) {
        return UserResponse.from(identity.currentUser(UUID.fromString(jwt.getSubject())));
    }
}
