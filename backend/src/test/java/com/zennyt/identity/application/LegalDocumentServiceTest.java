package com.zennyt.identity.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LegalDocumentServiceTest {

    private final LegalDocumentService service = new LegalDocumentService(new ObjectMapper());

    @Test
    void loadsTheTermsOfUseFromTheClasspath() {
        var document = service.load("terms-of-use");
        assertThat(document.title()).isEqualTo("Terms of Use & Conditions");
        assertThat(document.sections()).isNotEmpty();
        assertThat(document.sections().get(0).heading()).contains("Legal Notice");
    }

    @Test
    void loadsThePrivacyPolicyFromTheClasspath() {
        var document = service.load("privacy-policy");
        assertThat(document.title()).isEqualTo("Corporate Privacy Policy");
        assertThat(document.sections()).hasSize(16);
    }

    @Test
    void unknownOrUnsafeSlugsAreRejected() {
        assertThatThrownBy(() -> service.load("does-not-exist"))
            .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> service.load("../application"))
            .isInstanceOf(NotFoundException.class);
    }
}
