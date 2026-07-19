package com.zennyt.recruitment.domain;

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
    void submit_creates_application_in_PENDING() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());

        assertEquals(ApplicationStatus.PENDING, app.status());
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

    @Test
    void changeStatus_PENDING_to_SHORTLISTED() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());

        app.changeStatus(ApplicationStatus.SHORTLISTED);

        assertEquals(ApplicationStatus.SHORTLISTED, app.status());
    }

    @Test
    void changeStatus_SHORTLISTED_to_APPROVED() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());
        app.changeStatus(ApplicationStatus.SHORTLISTED);
        app.changeStatus(ApplicationStatus.APPROVED);
        assertEquals(ApplicationStatus.APPROVED, app.status());
    }

    @Test
    void changeStatus_SHORTLISTED_to_REJECTED() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());
        app.changeStatus(ApplicationStatus.SHORTLISTED);
        app.changeStatus(ApplicationStatus.REJECTED);
        assertEquals(ApplicationStatus.REJECTED, app.status());
    }

    @Test
    void invalid_transition_throws_and_emits_no_event() {
        Application app = Application.submit(UUID.randomUUID(), UUID.randomUUID());
        // PENDING -> APPROVED est interdit par la machine à états.
        assertThrows(IllegalArgumentException.class,
            () -> app.changeStatus(ApplicationStatus.APPROVED));

        assertEquals(ApplicationStatus.PENDING, app.status());
    }
}
