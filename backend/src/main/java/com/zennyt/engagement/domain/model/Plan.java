package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.PlanPeriod;

/**
 * Offre du catalogue (maquette 261/316). Vit en code (catalogue statique), pas en
 * base : les prix font foi dans l'App Store / Google Play, ce catalogue sert à
 * l'affichage. {@code productId} doit correspondre à l'identifiant configuré dans
 * les consoles de store.
 */
public record Plan(String code, String name, String description, long priceCents, String currency,
                   PlanPeriod period, boolean popular) {

    public String productId() {
        return code;
    }
}
