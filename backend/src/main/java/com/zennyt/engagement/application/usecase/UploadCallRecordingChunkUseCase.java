package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.port.EngagementMediaStoragePort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UploadCallRecordingChunkUseCase {

    private final EngagementMediaStoragePort storage;

    public ChunkUploadResult execute(String sessionId, int sequenceNumber, MultipartFile file) {
        try {
            String filename = String.format("%s_%d.mp4", sessionId, sequenceNumber);
            var stored = storage.upload(file.getBytes(), filename, file.getContentType(), EngagementMediaStoragePort.ResourceType.VIDEO);
            
            return new ChunkUploadResult(
                UUID.randomUUID().toString(),
                stored.url(),
                sessionId,
                sequenceNumber
            );
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload recording chunk", e);
        }
    }

    public record ChunkUploadResult(String chunkId, String url, String sessionId, int sequenceNumber) {}
}