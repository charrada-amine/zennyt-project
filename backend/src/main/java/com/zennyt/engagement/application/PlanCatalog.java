package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.Plan;
import com.zennyt.engagement.domain.vo.PlanPeriod;

import java.util.List;
import java.util.Optional;

/**
 * Catalogue des offres (maquette 261/316). Les prix font foi dans l'App Store /
 * Google Play ; ce catalogue sert à l'affichage et à associer un `productId` de
 * store à une offre. **Décision (à valider) :** les identifiants produits
 * (`productId`) doivent être créés dans les consoles de store avec ces codes.
 */
public final class PlanCatalog {

    private PlanCatalog() {}

    public static final List<Plan> PLANS = List.of(
        new Plan("recruiter_pro_monthly", "Recruiter Pro",
            "4 matchs / mois, 39 entretiens vidéo, 7 % de commission",
            3900, "EUR", PlanPeriod.MONTHLY, false),
        new Plan("recruiter_team_monthly", "Recruiter Team",
            "Entretiens vidéo illimités, commission réduite",
            9900, "EUR", PlanPeriod.MONTHLY, true),
        new Plan("video_interview_single", "Video-interview",
            "Un entretien vidéo à l'unité", 999, "EUR", PlanPeriod.NONE, false),
        new Plan("video_interview_bundle", "Video-interview bundle",
            "Pack d'entretiens vidéo", 1999, "EUR", PlanPeriod.NONE, false)
    );

    public static Optional<Plan> byCode(String code) {
        return PLANS.stream().filter(plan -> plan.code().equals(code)).findFirst();
    }
}
