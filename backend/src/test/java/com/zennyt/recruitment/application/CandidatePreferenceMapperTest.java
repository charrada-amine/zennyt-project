package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.WorkplaceType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class CandidatePreferenceMapperTest {

    @Test
    void mapsDirectWorkplaceTypeEquivalents() {
        assertThat(CandidatePreferenceMapper.toWorkplaceType("ONSITE")).isEqualTo(WorkplaceType.ON_SITE);
        assertThat(CandidatePreferenceMapper.toWorkplaceType("REMOTE")).isEqualTo(WorkplaceType.REMOTE);
        assertThat(CandidatePreferenceMapper.toWorkplaceType("HYBRID")).isEqualTo(WorkplaceType.HYBRID);
    }

    @Test
    void flexibleWorkplaceTypeHasNoEquivalentAndMeansNoPreference() {
        assertThat(CandidatePreferenceMapper.toWorkplaceType("FLEXIBLE")).isNull();
        assertThat(CandidatePreferenceMapper.toWorkplaceType(null)).isNull();
    }

    @Test
    void mapsDirectContractTypeEquivalentsAndClosestMatchForInternship() {
        assertThat(CandidatePreferenceMapper.toContractType("FULL_TIME")).isEqualTo(ContractType.FULL_TIME);
        assertThat(CandidatePreferenceMapper.toContractType("PART_TIME")).isEqualTo(ContractType.PART_TIME);
        assertThat(CandidatePreferenceMapper.toContractType("CONTRACT")).isEqualTo(ContractType.CONTRACT);
        assertThat(CandidatePreferenceMapper.toContractType("INTERNSHIP")).isEqualTo(ContractType.APPRENTICESHIP);
    }

    @Test
    void freelanceContractTypeHasNoEquivalentAndMeansNoPreference() {
        assertThat(CandidatePreferenceMapper.toContractType("FREELANCE")).isNull();
        assertThat(CandidatePreferenceMapper.toContractType(null)).isNull();
    }
}
