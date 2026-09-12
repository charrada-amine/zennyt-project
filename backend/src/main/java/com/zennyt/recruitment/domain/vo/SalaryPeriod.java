package com.zennyt.recruitment.domain.vo;

/**
 * Périodicité du salaire affiché (maquette 213) : montant mensuel ou annuel.
 * Le montant reste stocké brut (gross) dans {@code salaryMin}/{@code salaryMax} ;
 * la devise est portée séparément par {@code salaryCurrency}.
 */
public enum SalaryPeriod {
    MONTHLY,
    YEARLY
}
