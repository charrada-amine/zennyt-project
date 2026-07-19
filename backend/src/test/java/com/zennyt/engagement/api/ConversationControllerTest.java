package com.zennyt.engagement.api;

import com.zennyt.engagement.application.ActorDirectory;
import com.zennyt.engagement.application.usecase.EnsureConversationUseCase;
import com.zennyt.engagement.application.usecase.ListConversationsUseCase;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.shared.infrastructure.web.GlobalExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import java.util.UUID;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ConversationControllerTest {
    private static final UUID ACTOR_ID = UUID.randomUUID();
    private static final UUID APPLICATION_ID = UUID.randomUUID();

    private EnsureConversationUseCase ensureConversation;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        ensureConversation = mock(EnsureConversationUseCase.class);
        ActorDirectory actors = mock(ActorDirectory.class);
        when(actors.displayName(any())).thenReturn("Grace Hopper");
        when(actors.photoUrl(any())).thenReturn(null);
        var controller = new ConversationController(
            mock(ListConversationsUseCase.class), ensureConversation, actors);
        var validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();
        mvc = MockMvcBuilders.standaloneSetup(controller)
            .setControllerAdvice(new GlobalExceptionHandler())
            .setValidator(validator)
            .build();
    }

    @Test
    void returns_201_only_when_the_conversation_was_created() throws Exception {
        Conversation conversation = conversation();
        when(ensureConversation.execute(ACTOR_ID, APPLICATION_ID))
            .thenReturn(new EnsureConversationUseCase.Result(conversation, true));

        mvc.perform(post("/api/v1/conversations")
                .with(actor())
                .contentType("application/json")
                .content("{\"applicationId\":\"" + APPLICATION_ID + "\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.applicationId").value(APPLICATION_ID.toString()));
    }

    @Test
    void returns_200_with_the_same_resource_when_it_already_exists() throws Exception {
        Conversation conversation = conversation();
        when(ensureConversation.execute(ACTOR_ID, APPLICATION_ID))
            .thenReturn(new EnsureConversationUseCase.Result(conversation, false));

        mvc.perform(post("/api/v1/conversations")
                .with(actor())
                .contentType("application/json")
                .content("{\"applicationId\":\"" + APPLICATION_ID + "\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(conversation.id().toString()));
    }

    @Test
    void rejects_missing_or_malformed_application_id() throws Exception {
        mvc.perform(post("/api/v1/conversations").with(actor())
                .contentType("application/json").content("{}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/conversations").with(actor())
                .contentType("application/json").content("{\"applicationId\":\"not-a-uuid\"}"))
            .andExpect(status().isBadRequest());

        verifyNoInteractions(ensureConversation);
    }

    private Conversation conversation() {
        return Conversation.create(APPLICATION_ID, UUID.randomUUID(), ACTOR_ID,
            UUID.randomUUID(), "Backend Engineer");
    }

    private RequestPostProcessor actor() {
        return request -> {
            request.setUserPrincipal(() -> ACTOR_ID.toString());
            return request;
        };
    }
}
