package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.EngagementSupportDtos.MediaUploadResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.UploadEngagementMediaUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

@RestController @RequestMapping("/api/v1/media") @RequiredArgsConstructor
public class EngagementMediaController {
    private final UploadEngagementMediaUseCase upload;
    @PostMapping(value="/upload", consumes="multipart/form-data") @EngagementAuthenticated
    public ResponseEntity<MediaUploadResponse> upload(@RequestPart("file") MultipartFile file) throws IOException {
        var stored = upload.execute(file.getBytes(), file.getOriginalFilename(), file.getContentType());
        return ResponseEntity.status(HttpStatus.CREATED).body(new MediaUploadResponse(stored.url(), stored.publicId(), stored.resourceType()));
    }
}
