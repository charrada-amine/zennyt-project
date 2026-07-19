package com.zennyt.engagement.application.port;

public interface EngagementMediaStoragePort {
    StoredMedia upload(byte[] content, String filename, String contentType, ResourceType resourceType);
    record StoredMedia(String url, String publicId, String resourceType) {}
    enum ResourceType { IMAGE, VIDEO, RAW }
}
