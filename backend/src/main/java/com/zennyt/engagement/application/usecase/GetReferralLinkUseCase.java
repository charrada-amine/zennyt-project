package com.zennyt.engagement.application.usecase;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Cas d'usage : construire le lien de parrainage de l'utilisateur.
 *
 * <p>Le code est l'identifiant public de l'utilisateur (aucune table
 * supplémentaire). Le montant du bonus est configurable : la maquette affiche
 * « 500€ » tandis que le §12 des Conditions parle de 800 USD — incohérence
 * tracée comme décision à valider, la config tranche sans coder l'un en dur.
 */
@Service
public class GetReferralLinkUseCase {

    public record Link(String code, String url, int bonusAmount, String bonusCurrency) {}

    private final String linkBase;
    private final int bonusAmount;
    private final String bonusCurrency;

    public GetReferralLinkUseCase(
            @Value("${zennyt.referral.link-base:https://www.zennyt.com/invite}") String linkBase,
            @Value("${zennyt.referral.bonus-amount:800}") int bonusAmount,
            @Value("${zennyt.referral.bonus-currency:USD}") String bonusCurrency) {
        this.linkBase = linkBase;
        this.bonusAmount = bonusAmount;
        this.bonusCurrency = bonusCurrency;
    }

    public Link execute(UUID referrerUserId) {
        String code = referrerUserId.toString();
        return new Link(code, linkBase + "/" + code, bonusAmount, bonusCurrency);
    }
}
