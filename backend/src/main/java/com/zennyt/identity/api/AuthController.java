package com.zennyt.identity.api;

import com.zennyt.identity.application.AuthService;
import com.zennyt.identity.application.IdentityService;
import com.zennyt.identity.api.security.Authenticated;
import com.zennyt.identity.api.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import static com.zennyt.identity.api.IdentityDtos.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService auth;
    private final IdentityService identity;

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

    @PostMapping("/change-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Authenticated
    public void changePassword(@CurrentUserId UUID userId,
                               @Valid @RequestBody ChangePasswordRequest request) {
        auth.changePassword(userId, request.currentPassword(), request.newPassword());
    }

    @PostMapping("/forgot-password")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        auth.forgotPassword(request.email());
    }

    @PostMapping("/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        auth.resetPassword(request.email(), request.code(), request.newPassword());
    }

    @GetMapping("/me")
    @Authenticated
    public UserResponse me(@CurrentUserId UUID userId) {
        return UserResponse.from(identity.currentUser(userId));
    }
}
