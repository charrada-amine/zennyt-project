package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Referral;
import com.zennyt.engagement.domain.repository.ReferralRepository;
import com.zennyt.engagement.domain.vo.ReferralStatus;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.domain.vo.Email;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : inviter une personne à rejoindre la plateforme (parrainage). */
@Service
@RequiredArgsConstructor
public class InviteReferralUseCase {

    /** PROVISOIRE — à valider : plafond d'invitations en attente par parrain (anti-spam). */
    private static final long MAX_PENDING_REFERRAL_INVITES = 100;

    private final ReferralRepository referrals;

    @Transactional
    public Referral execute(UUID referrerUserId, String rawEmail) {
        Email email;
        try {
            email = new Email(rawEmail);
        } catch (RuntimeException invalid) {
            throw new IllegalArgumentException("Adresse e-mail invalide");
        }
        if (referrals.existsByReferrerUserIdAndInviteeEmail(referrerUserId, email.value())) {
            throw new ConflictException("Cette adresse a déjà été invitée");
        }
        // Garde-fou anti-spam : sans plafond, un compte peut générer des invitations
        // (et un jour des e-mails) à l'infini.
        if (referrals.countByReferrerUserIdAndStatus(referrerUserId, ReferralStatus.INVITED)
                >= MAX_PENDING_REFERRAL_INVITES) {
            throw new ConflictException("Trop d'invitations en attente");
        }
        return referrals.save(Referral.invite(referrerUserId, email.value()));
    }
}
