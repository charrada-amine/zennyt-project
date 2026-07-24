package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.CallSession;
import com.zennyt.engagement.domain.vo.CallStatus;
import com.zennyt.engagement.domain.vo.CallType;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class CallSessionTest {
    @Test void only_counterpart_can_join_and_any_participant_can_end() {
        UUID initiator = UUID.randomUUID(), counterpart = UUID.randomUUID();
        CallSession call = CallSession.initiate(UUID.randomUUID(), CallType.VIDEO, initiator, counterpart, "offer");
        assertThrows(IllegalArgumentException.class, () -> call.join(initiator, "answer"));
        call.join(counterpart, "answer");
        assertEquals(CallStatus.IN_PROGRESS, call.status());
        call.end(initiator);
        assertEquals(CallStatus.ENDED, call.status());
        assertNotNull(call.durationSeconds());
    }
}
