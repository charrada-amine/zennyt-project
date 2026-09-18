package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Referral;
import com.zennyt.engagement.domain.repository.ReferralRepository;
import com.zennyt.engagement.domain.vo.ReferralStatus;
import com.zennyt.shared.application.exception.ConflictException;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class InviteReferralUseCaseTest {

    private static final UUID REFERRER = UUID.randomUUID();

    private final ReferralRepository referrals = mock(ReferralRepository.class);
    private final InviteReferralUseCase useCase = new InviteReferralUseCase(referrals);

    @Test
    void createsAnInvitedReferralAndNormalisesTheEmail() {
        when(referrals.existsByReferrerUserIdAndInviteeEmail(REFERRER, "friend@example.com"))
            .thenReturn(false);
        when(referrals.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        Referral referral = useCase.execute(REFERRER, "Friend@Example.com");

        assertThat(referral.status()).isEqualTo(ReferralStatus.INVITED);
        assertThat(referral.inviteeEmail()).isEqualTo("friend@example.com");
        assertThat(referral.referrerUserId()).isEqualTo(REFERRER);
    }

    @Test
    void rejectsADuplicateInvitation() {
        when(referrals.existsByReferrerUserIdAndInviteeEmail(REFERRER, "friend@example.com"))
            .thenReturn(true);

        assertThatThrownBy(() -> useCase.execute(REFERRER, "friend@example.com"))
            .isInstanceOf(ConflictException.class);
        verify(referrals, never()).save(any());
    }

    @Test
    void rejectsInvitesAtThePendingLimit() {
        when(referrals.countByReferrerUserIdAndStatus(REFERRER, ReferralStatus.INVITED))
            .thenReturn(100L);

        assertThatThrownBy(() -> useCase.execute(REFERRER, "friend@example.com"))
            .isInstanceOf(ConflictException.class);
        verify(referrals, never()).save(any());
    }

    @Test
    void acceptsAnInviteBelowThePendingLimit() {
        when(referrals.countByReferrerUserIdAndStatus(REFERRER, ReferralStatus.INVITED))
            .thenReturn(99L);
        when(referrals.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(useCase.execute(REFERRER, "friend@example.com").status())
            .isEqualTo(ReferralStatus.INVITED);
    }

    @Test
    void rejectsAnInvalidEmail() {
        assertThatThrownBy(() -> useCase.execute(REFERRER, "not-an-email"))
            .isInstanceOf(IllegalArgumentException.class);
        verify(referrals, never()).save(any());
    }
}
