package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.RegisterPushDeviceUseCase;
import com.zennyt.engagement.domain.model.PushDevice;
import com.zennyt.engagement.domain.repository.PushDeviceRepository;
import com.zennyt.engagement.domain.vo.PushPlatform;
import com.zennyt.shared.application.exception.ConflictException;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class RegisterPushDeviceUseCaseTest {
    private final PushDeviceRepository devices = mock(PushDeviceRepository.class);
    private final RegisterPushDeviceUseCase useCase = new RegisterPushDeviceUseCase(devices);

    @Test
    void refreshes_an_existing_token_owned_by_the_actor() {
        UUID actorId = UUID.randomUUID();
        PushDevice existing = PushDevice.register(actorId, "token", PushPlatform.IOS, "old");
        when(devices.findByToken("token")).thenReturn(Optional.of(existing));
        when(devices.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        PushDevice result = useCase.execute(actorId, "token", PushPlatform.ANDROID, "Pixel");

        assertThat(result.id()).isEqualTo(existing.id());
        assertThat(result.platform()).isEqualTo(PushPlatform.ANDROID);
        assertThat(result.deviceName()).isEqualTo("Pixel");
    }

    @Test
    void rejects_a_token_owned_by_another_actor() {
        PushDevice existing = PushDevice.register(
            UUID.randomUUID(), "token", PushPlatform.IOS, "iPhone");
        when(devices.findByToken("token")).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> useCase.execute(
            UUID.randomUUID(), "token", PushPlatform.ANDROID, "Pixel"))
            .isInstanceOf(ConflictException.class);
        verify(devices, never()).save(any());
    }
}
