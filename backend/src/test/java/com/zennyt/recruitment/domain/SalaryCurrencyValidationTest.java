package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.Location;
import com.zennyt.recruitment.domain.vo.SalaryPeriod;
import com.zennyt.recruitment.domain.vo.WorkplaceType;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SalaryCurrencyValidationTest {

    private static final UUID RECRUITER = UUID.randomUUID();

    private static JobOffer rehydrateWithCurrency(String currency) {
        return JobOffer.rehydrate(UUID.randomUUID(), RECRUITER, null, "Titre",
            new Location("Tunis", "TN"), 1000.0, 2000.0, ContractType.FULL_TIME,
            WorkplaceType.REMOTE, ExperienceLevel.JUNIOR, "desc", null, null, null,
            null, null, null, null, false,
            com.zennyt.recruitment.domain.vo.JobOfferStatus.ACTIVE,
            java.time.Instant.now(), java.time.Instant.now(), currency, SalaryPeriod.MONTHLY);
    }

    private static JobOffer createOffer() {
        return JobOffer.create(RECRUITER, "Titre", "desc", ContractType.FULL_TIME,
            WorkplaceType.REMOTE, ExperienceLevel.JUNIOR, new Location("Tunis", "TN"));
    }

    @Test
    void rehydrateAcceptsEveryContractCurrency() {
        for (com.zennyt.recruitment.domain.vo.SalaryCurrency currency :
            com.zennyt.recruitment.domain.vo.SalaryCurrency.values()) {
            assertThat(rehydrateWithCurrency(currency.name()).salaryCurrency())
                .isEqualTo(currency.name());
        }
    }

    @Test
    void rehydrateDefaultsToEurWhenCurrencyAbsent() {
        assertThat(rehydrateWithCurrency(null).salaryCurrency()).isEqualTo("EUR");
    }

    @Test
    void rehydrateRejectsCurrencyOutsideV79Constraint() {
        assertThatThrownBy(() -> rehydrateWithCurrency("XXX"))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> rehydrateWithCurrency("eur"))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void updateAcceptsContractCurrenciesAndDefaultsToEur() {
        JobOffer offer = createOffer();
        for (com.zennyt.recruitment.domain.vo.SalaryCurrency currency :
            com.zennyt.recruitment.domain.vo.SalaryCurrency.values()) {
            offer.update("Titre", new Location("Tunis", "TN"), 1000.0, 2000.0,
                ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.JUNIOR,
                "desc", null, null, null, null, null, null, UUID.randomUUID(), false,
                currency.name(), SalaryPeriod.MONTHLY);
            assertThat(offer.salaryCurrency()).isEqualTo(currency.name());
        }
        offer.update("Titre", new Location("Tunis", "TN"), 1000.0, 2000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.JUNIOR,
            "desc", null, null, null, null, null, null, UUID.randomUUID(), false,
            null, SalaryPeriod.MONTHLY);
        assertThat(offer.salaryCurrency()).isEqualTo("EUR");
    }

    @Test
    void updateRejectsCurrencyOutsideV79Constraint() {
        JobOffer offer = createOffer();
        assertThatThrownBy(() -> offer.update("Titre", new Location("Tunis", "TN"), 1000.0, 2000.0,
                ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.JUNIOR,
                "desc", null, null, null, null, null, null, UUID.randomUUID(), false,
                "JPY", SalaryPeriod.MONTHLY))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
