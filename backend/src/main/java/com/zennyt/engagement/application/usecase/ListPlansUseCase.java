package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.PlanCatalog;
import com.zennyt.engagement.domain.model.Plan;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Cas d'usage : lister le catalogue d'offres (affichage). */
@Service
public class ListPlansUseCase {

    @Transactional(readOnly = true)
    public List<Plan> execute() {
        return PlanCatalog.PLANS;
    }
}
