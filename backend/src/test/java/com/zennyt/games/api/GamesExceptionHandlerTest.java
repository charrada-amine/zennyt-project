package com.zennyt.games.api;

import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GamesExceptionHandlerTest {

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(new ThrowingController())
            .setControllerAdvice(new GamesExceptionHandler())
            .build();
    }

    @Test
    void mapsMalformedDomainPayloadToContractualBadRequest() throws Exception {
        mvc.perform(get("/test-games-errors/bad-request"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.error").value("Bad Request"))
            .andExpect(jsonPath("$.message").value("trace invalide"))
            .andExpect(jsonPath("$.path").value("/test-games-errors/bad-request"));
    }

    @Test
    void mapsOwnershipAndMissingSessionErrors() throws Exception {
        mvc.perform(get("/test-games-errors/forbidden"))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.status").value(403));

        mvc.perform(get("/test-games-errors/not-found"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @RestController
    static class ThrowingController {
        @GetMapping("/test-games-errors/bad-request")
        void badRequest() {
            throw new IllegalArgumentException("trace invalide");
        }

        @GetMapping("/test-games-errors/forbidden")
        void forbidden() {
            throw new ForbiddenException("interdit");
        }

        @GetMapping("/test-games-errors/not-found")
        void notFound() {
            throw new NotFoundException("absent");
        }
    }
}
