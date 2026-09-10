package com.zennyt.engagement.api.dto;

import lombok.Value;

@Value
public class CallRecordingChunkResponse {
    String chunkId;
    String url;
    String sessionId;
    int sequenceNumber;
}