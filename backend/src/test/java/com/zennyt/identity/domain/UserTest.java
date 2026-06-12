package com.zennyt.identity.domain;

import com.zennyt.identity.domain.model.Role;
import com.zennyt.identity.domain.model.User;
import com.zennyt.shared.domain.vo.Email;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UserTest {
    @Test
    void registrationRequiresTermsAcceptance() {
        assertThatThrownBy(() -> User.register("Ada", "Lovelace",
            new Email("ada@example.com"), null, "hash", Role.CANDIDATE,
            null, null, null, false))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("conditions");
    }

    @Test
    void registeredUserHasStablePublicIdentityAndActiveDefaults() {
        User user = User.register("Ada", "Lovelace", new Email("ADA@example.com"),
            null, "hash", Role.STUDENT, "Tunis", "Tunisia", null, true);

        assertThat(user.publicId()).isNotNull();
        assertThat(user.email().value()).isEqualTo("ada@example.com");
        assertThat(user.active()).isTrue();
        assertThat(user.emailVerified()).isFalse();
        assertThat(user.role().hasProfessionalProfile()).isTrue();
    }

    @Test
    void publicRoleChangeCannotGrantAdmin() {
        User user = User.register("Ada", "Lovelace", new Email("ada@example.com"),
            null, "hash", Role.CANDIDATE, null, null, null, true);

        assertThatThrownBy(() -> user.changeRole(Role.ADMIN))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void socialRegistrationStartsWithVerifiedEmail() {
        User user = User.registerSocial("Ada", "Lovelace", new Email("ada@example.com"),
            "hash", Role.CANDIDATE, "https://example.com/avatar.png", true);

        assertThat(user.emailVerified()).isTrue();
        assertThat(user.profileImageUrl()).isEqualTo("https://example.com/avatar.png");
    }
}
