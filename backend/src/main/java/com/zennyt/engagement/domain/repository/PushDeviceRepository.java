package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.PushDevice;

import java.util.Optional;

public interface PushDeviceRepository {
    PushDevice save(PushDevice pushDevice);
    Optional<PushDevice> findByToken(String token);
}
