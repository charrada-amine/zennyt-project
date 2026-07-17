package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.VideoConferencePayment;

import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de paiements visioconférence.
 */
public interface VideoConferencePaymentRepository {

    VideoConferencePayment save(VideoConferencePayment payment);

    Optional<VideoConferencePayment> findById(UUID id);
}
