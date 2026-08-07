package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.SourceDocumentExtractorPort;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Extraction de texte depuis un fichier source uploadé (livre, manuel, MCQ
 * existant…). Seul le PDF est supporté pour l'instant — signature de fichier
 * vérifiée, pas seulement le content-type déclaré par le client.
 */
@Component
public class PdfSourceDocumentExtractor implements SourceDocumentExtractorPort {

    private static final byte[] PDF_SIGNATURE = {0x25, 0x50, 0x44, 0x46, 0x2D}; // "%PDF-"

    @Override
    public String extractText(byte[] content) {
        if (!startsWith(content, PDF_SIGNATURE)) {
            throw new IllegalArgumentException("Seul le format PDF est supporté pour le moment");
        }
        try (PDDocument document = Loader.loadPDF(content)) {
            String text = new PDFTextStripper().getText(document);
            if (text == null || text.isBlank()) {
                throw new IllegalArgumentException("Le fichier ne contient aucun texte exploitable");
            }
            return text;
        } catch (IOException e) {
            throw new IllegalArgumentException("Fichier PDF illisible ou corrompu", e);
        }
    }

    private static boolean startsWith(byte[] bytes, byte[] signature) {
        if (bytes.length < signature.length) return false;
        for (int i = 0; i < signature.length; i++) {
            if (bytes[i] != signature[i]) return false;
        }
        return true;
    }
}
