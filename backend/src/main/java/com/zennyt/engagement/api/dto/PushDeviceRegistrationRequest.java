package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.vo.PushPlatform;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PushDeviceRegistrationRequest(@NotBlank String token,
                                            @NotNull PushPlatform platform,
                                            String deviceName) {}
