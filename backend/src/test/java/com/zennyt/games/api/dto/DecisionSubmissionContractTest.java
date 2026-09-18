package com.zennyt.games.api.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.UnrecognizedPropertyException;
import com.zennyt.games.domain.vo.DecisionMetrics;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class DecisionSubmissionContractTest {
    private final ObjectMapper mapper = new ObjectMapper();

    private static final String PAYLOAD = """
        {"miniGame":"DECISION_CORE","metrics":{
          "decisionItems":[
            {"itemId":"ER-1","dimension":"ER","selectedOptionId":"ER-1-A",
             "responseTimeMs":3200,"answered":true,"decisionChangesCount":1},
            {"itemId":"DT-1","dimension":"DT","responseTimeMs":8400,"answered":false}
          ],"sessionLanguage":"fr","administrationMode":"SUPERVISED"
        }}
        """;

    @Test
    void decisionItemsMapsAnswersAndTimeoutsToDomainWithoutClientScore() throws Exception {
        var request = mapper.readValue(PAYLOAD, SubmitResultRequest.class);
        var metrics = assertInstanceOf(DecisionMetrics.class, request.toMetrics());
        assertEquals(2, metrics.items().size());
        assertEquals("fr", metrics.sessionLanguage());
        assertEquals("ER-1-A", metrics.items().get(0).selectedOptionId());
        assertEquals(3200, metrics.items().get(0).responseTimeMs());
        assertEquals(1, metrics.items().get(0).decisionChangesCount());
        assertFalse(metrics.items().get(1).answered());
        assertNull(metrics.items().get(1).selectedOptionId());
    }

    @Test
    void itemsIsTheFormKeyAndIsRejectedInTheSubmissionPayload() {
        assertThrows(UnrecognizedPropertyException.class,
            () -> mapper.readValue(PAYLOAD.replace("decisionItems", "items"), SubmitResultRequest.class));
    }
}
