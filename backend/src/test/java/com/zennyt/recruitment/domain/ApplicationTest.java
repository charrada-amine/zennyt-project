package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests unitaires de l'agrégat Application — aucun contexte Spring, aucune base.
 * C'est le bénéfice d'un domaine pur : rapide et isolé.
 */
class ApplicationTest {

    @Test
    void submit_creates_application_in_PENDING_and_emits_event() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());

        assertEquals(ApplicationStatus.PENDING, app.status());
        assertEquals(1, app.domainEvents().size());
        assertInstanceOf(ApplicationSubmittedEvent.class, app.domainEvents().get(0));
    }

    @Test
    void valid_status_transition_succeeds() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());
        app.changeStatus(ApplicationStatus.SHORTLISTED);
        assertEquals(ApplicationStatus.SHORTLISTED, app.status());
    }

    @Test
    void changeStatus_to_APPROVED_after_SHORTLISTED() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());
        app.changeStatus(ApplicationStatus.SHORTLISTED);
        app.changeStatus(ApplicationStatus.APPROVED);
        assertEquals(ApplicationStatus.APPROVED, app.status());
    }
}
