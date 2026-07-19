package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.MessageSenderRole;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.engagement.domain.vo.PushPlatform;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

/** Verrouille la parité des value objects avec contracts/engagement.openapi.yaml. */
class EngagementValueObjectsContractTest {

    @Test
    void notificationTypes_match_the_target_contract_exactly() {
        assertArrayEquals(new NotificationType[]{
            NotificationType.APPLICATION_VIEWED,
            NotificationType.APPLICATION_STATUS_CHANGED,
            NotificationType.NEW_MESSAGE,
            NotificationType.JOB_MATCH,
            NotificationType.PROFILE_VIEWED,
            NotificationType.NEW_COMMENT,
            NotificationType.NEW_LIKE
        }, NotificationType.values());
    }

    @Test
    void messageContentTypes_match_the_target_contract_exactly() {
        assertArrayEquals(new MessageContentType[]{
            MessageContentType.TEXT,
            MessageContentType.IMAGE,
            MessageContentType.FILE,
            MessageContentType.SYSTEM
        }, MessageContentType.values());
    }

    @Test
    void messageSenderRoles_match_the_target_contract_exactly() {
        assertArrayEquals(new MessageSenderRole[]{
            MessageSenderRole.CANDIDATE,
            MessageSenderRole.RECRUITER,
            MessageSenderRole.SYSTEM
        }, MessageSenderRole.values());
    }

    @Test
    void pushPlatforms_match_the_target_contract_exactly() {
        assertArrayEquals(new PushPlatform[]{
            PushPlatform.ANDROID,
            PushPlatform.IOS
        }, PushPlatform.values());
    }
}
