package com.zennyt.identity.api;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UploadValidationTest {

    @Test
    void acceptsPdfWhenMimeAndSignatureMatch() throws Exception {
        var file = new MockMultipartFile("file", "cv.pdf", "application/pdf",
            "%PDF-1.7 valid".getBytes());

        assertThat(UploadValidation.cv(file)).isEqualTo(file.getBytes());
    }

    @Test
    void rejectsMimeSpoofing() {
        var file = new MockMultipartFile("file", "fake.pdf", "application/pdf",
            "not a pdf".getBytes());

        assertThatThrownBy(() -> UploadValidation.cv(file))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("contenu invalide");
    }

    @Test
    void acceptsPngJpegAndWebpSignatures() {
        assertThat(UploadValidation.image(file("image/png",
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A), "avatar")).isNotEmpty();
        assertThat(UploadValidation.image(file("image/jpeg", 0xFF, 0xD8, 0xFF), "avatar"))
            .isNotEmpty();
        assertThat(UploadValidation.image(file("image/webp",
            0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50), "avatar"))
            .isNotEmpty();
    }

    @Test
    void rejectsEmptyAndOversizedFiles() {
        assertThatThrownBy(() -> UploadValidation.cv(
            new MockMultipartFile("file", "cv.pdf", "application/pdf", new byte[0])))
            .hasMessageContaining("obligatoire");
        assertThatThrownBy(() -> UploadValidation.cv(
            new MockMultipartFile("file", "cv.pdf", "application/pdf",
                new byte[(int) UploadValidation.MAX_FILE_SIZE + 1])))
            .hasMessageContaining("5 Mo");
    }

    private static MockMultipartFile file(String contentType, int... bytes) {
        byte[] content = new byte[bytes.length];
        for (int i = 0; i < bytes.length; i++) content[i] = (byte) bytes[i];
        return new MockMultipartFile("file", "upload", contentType, content);
    }
}
