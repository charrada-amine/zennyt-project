package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.event.OtpRequestedEvent;
import com.zennyt.recruitment.domain.model.OtpChallenge;
import com.zennyt.recruitment.domain.repository.OtpChallengeRepository;
import com.zennyt.recruitment.domain.vo.OtpPurpose;
import com.zennyt.shared.application.exception.ConflictException;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.authentication.BadCredentialsException;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class OtpServiceTest {
    private final OtpChallengeRepository repository = mock(OtpChallengeRepository.class);
    private final ApplicationEventPublisher publisher = mock(ApplicationEventPublisher.class);

    @Test
    void issuesHashedCodeAndConsumesItOnce() {
        AtomicReference<OtpChallenge> stored = repositoryState();
        OtpService service = new OtpService(repository, publisher, Duration.ofMinutes(10), 3);
        UUID resourceId = UUID.randomUUID();
        UUID recipientId = UUID.randomUUID();

        service.issue(resourceId, recipientId, OtpPurpose.PAYMENT);

        var eventCaptor = org.mockito.ArgumentCaptor.forClass(OtpRequestedEvent.class);
        verify(publisher).publishEvent(eventCaptor.capture());
        String clearCode = eventCaptor.getValue().oneTimeCode();
        assertThat(clearCode).matches("\\d{6}");
        assertThat(stored.get().codeHash()).doesNotContain(clearCode);

        assertThatCode(() -> service.verify(resourceId, recipientId,
            OtpPurpose.PAYMENT, clearCode)).doesNotThrowAnyException();
        assertThat(stored.get().consumedAt()).isNotNull();
        assertThatThrownBy(() -> service.verify(resourceId, recipientId,
            OtpPurpose.PAYMENT, clearCode))
            .isInstanceOf(ConflictException.class)
            .hasMessageContaining("déjà été utilisé");
    }

    @Test
    void limitsAttemptsAndDoesNotIssueDuplicateActiveChallenge() {
        AtomicReference<OtpChallenge> stored = repositoryState();
        OtpService service = new OtpService(repository, publisher, Duration.ofMinutes(10), 2);
        UUID resourceId = UUID.randomUUID();
        UUID recipientId = UUID.randomUUID();

        service.issue(resourceId, recipientId, OtpPurpose.JOB_OPPORTUNITY);
        service.issue(resourceId, recipientId, OtpPurpose.JOB_OPPORTUNITY);
        verify(publisher, times(1)).publishEvent(any(OtpRequestedEvent.class));

        assertThatThrownBy(() -> service.verify(resourceId, recipientId,
            OtpPurpose.JOB_OPPORTUNITY, "000000"))
            .isInstanceOf(BadCredentialsException.class);
        assertThat(stored.get().attemptsRemaining()).isEqualTo(1);
        assertThatThrownBy(() -> service.verify(resourceId, UUID.randomUUID(),
            OtpPurpose.JOB_OPPORTUNITY, "000000"))
            .isInstanceOf(BadCredentialsException.class);
        assertThat(stored.get().attemptsRemaining()).isEqualTo(1);
    }

    private AtomicReference<OtpChallenge> repositoryState() {
        AtomicReference<OtpChallenge> stored = new AtomicReference<>();
        when(repository.findLatest(any(), any())).thenAnswer(invocation -> Optional.ofNullable(stored.get()));
        when(repository.save(any())).thenAnswer(invocation -> {
            OtpChallenge challenge = invocation.getArgument(0);
            stored.set(challenge);
            return challenge;
        });
        return stored;
    }
}
