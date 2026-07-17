package com.zennyt.identity.api;

import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Set;

final class UploadValidation {
    static final long MAX_FILE_SIZE = 5L * 1024 * 1024;
    private static final Set<String> IMAGE_TYPES = Set.of(
        "image/png", "image/jpeg", "image/webp");
    private static final Set<String> CV_TYPES = Set.of(
        "application/pdf", "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document");

    private UploadValidation() {}

    static byte[] image(MultipartFile file, String label) {
        byte[] bytes = read(file, label);
        String type = file.getContentType();
        if (!IMAGE_TYPES.contains(type) || !matchesImageSignature(bytes, type)) {
            throw new IllegalArgumentException(
                "Format d'image non supporté ou contenu invalide (PNG, JPEG ou WEBP attendu)");
        }
        return bytes;
    }

    static byte[] cv(MultipartFile file) {
        byte[] bytes = read(file, "CV");
        String type = file.getContentType();
        if (!CV_TYPES.contains(type) || !matchesCvSignature(bytes, type)) {
            throw new IllegalArgumentException(
                "Format de CV non supporté ou contenu invalide (PDF, DOC ou DOCX attendu)");
        }
        return bytes;
    }

    private static byte[] read(MultipartFile file, String label) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Le fichier " + label + " est obligatoire");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("Le fichier dépasse la limite de 5 Mo");
        }
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de la lecture du fichier " + label, e);
        }
    }

    private static boolean matchesImageSignature(byte[] bytes, String type) {
        return switch (type) {
            case "image/png" -> startsWith(bytes, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);
            case "image/jpeg" -> startsWith(bytes, 0xFF, 0xD8, 0xFF);
            case "image/webp" -> bytes.length >= 12
                && startsWith(bytes, 0x52, 0x49, 0x46, 0x46)
                && bytes[8] == 0x57 && bytes[9] == 0x45
                && bytes[10] == 0x42 && bytes[11] == 0x50;
            default -> false;
        };
    }

    private static boolean matchesCvSignature(byte[] bytes, String type) {
        return switch (type) {
            case "application/pdf" -> startsWith(bytes, 0x25, 0x50, 0x44, 0x46, 0x2D);
            case "application/msword" -> startsWith(bytes,
                0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1);
            case "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ->
                startsWith(bytes, 0x50, 0x4B, 0x03, 0x04);
            default -> false;
        };
    }

    private static boolean startsWith(byte[] bytes, int... signature) {
        if (bytes.length < signature.length) return false;
        for (int i = 0; i < signature.length; i++) {
            if ((bytes[i] & 0xFF) != signature[i]) return false;
        }
        return true;
    }
}
