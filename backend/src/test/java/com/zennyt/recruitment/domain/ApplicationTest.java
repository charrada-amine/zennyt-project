package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test unitaire de l'agrégat — aucun contexte Spring, aucune base.
 * C'est le bénéfice d'un domaine pur : rapide et isolé.
 */
class ApplicationTest {

    @Test
    void submit_creates_application_in_SUBMITTED_and_emits_event() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID(), "Lettre");

        assertEquals(ApplicationStatus.SUBMITTED, app.status());
        assertEquals(1, app.domainEvents().size());
        assertInstanceOf(ApplicationSubmittedEvent.class, app.domainEvents().get(0));
    }

    @Test
    void valid_status_transition_succeeds() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID(), null);
        app.changeStatus(ApplicationStatus.VIEWED);
        assertEquals(ApplicationStatus.VIEWED, app.status());
    }

    @Test
    void invalid_status_transition_is_rejected() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID(), null);
        // SUBMITTED -> OFFER est interdit par la machine à états
        assertThrows(IllegalArgumentException.class,
            () -> app.changeStatus(ApplicationStatus.OFFER));
    }
}
