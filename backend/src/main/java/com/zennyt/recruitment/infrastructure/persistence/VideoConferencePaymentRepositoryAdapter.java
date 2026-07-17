package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.VideoConferencePayment;
import com.zennyt.recruitment.domain.repository.VideoConferencePaymentRepository;
import com.zennyt.recruitment.domain.vo.Money;
import org.springframework.stereotype.Component;
import java.util.Optional;
import java.util.UUID;

@Component
public class VideoConferencePaymentRepositoryAdapter implements VideoConferencePaymentRepository {
    private final JpaVideoConferencePaymentRepository jpa;
    public VideoConferencePaymentRepositoryAdapter(JpaVideoConferencePaymentRepository jpa) { this.jpa = jpa; }

    @Override public VideoConferencePayment save(VideoConferencePayment p) { return toDomain(jpa.save(toEntity(p))); }
    @Override public Optional<VideoConferencePayment> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    private VideoConferencePaymentEntity toEntity(VideoConferencePayment p) {
        VideoConferencePaymentEntity e = new VideoConferencePaymentEntity();
        e.setId(p.id()); e.setRecruiterId(p.recruiterId()); e.setCandidateId(p.candidateId());
        e.setMatchId(p.matchId()); e.setAmount(p.amount().amount()); e.setTax(p.tax().amount());
        e.setTotal(p.total().amount()); e.setCurrency(p.amount().currency());
        e.setStatus(p.status()); e.setPaymentMethodLast4(p.paymentMethodLast4());
        e.setPaymentMethodType(p.paymentMethodType()); e.setOtpVerified(p.otpVerified());
        e.setCreatedAt(p.createdAt()); e.setConfirmedAt(p.confirmedAt());
        return e;
    }

    private VideoConferencePayment toDomain(VideoConferencePaymentEntity e) {
        Money amount = new Money(e.getAmount(), e.getCurrency());
        Money tax = new Money(e.getTax(), e.getCurrency());
        Money total = new Money(e.getTotal(), e.getCurrency());
        return VideoConferencePayment.rehydrate(e.getId(), e.getRecruiterId(), e.getCandidateId(),
            e.getMatchId(), amount, tax, total, e.getStatus(), e.getPaymentMethodLast4(),
            e.getPaymentMethodType(), e.isOtpVerified(), e.getCreatedAt(), e.getConfirmedAt());
    }
}
