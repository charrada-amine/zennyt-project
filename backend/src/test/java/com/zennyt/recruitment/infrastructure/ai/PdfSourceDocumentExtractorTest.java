package com.zennyt.recruitment.infrastructure.ai;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PdfSourceDocumentExtractorTest {
    private final PdfSourceDocumentExtractor extractor = new PdfSourceDocumentExtractor();

    @Test
    void extractsTextFromAValidPdf() throws IOException {
        byte[] pdf = buildPdf("Senior React developer role description");

        String text = extractor.extractText(pdf);

        assertThat(text).contains("Senior React developer role description");
    }

    @Test
    void nonPdfContentRejected() {
        assertThatThrownBy(() -> extractor.extractText("not a pdf".getBytes()))
            .isInstanceOf(IllegalArgumentException.class);
    }

    private static byte[] buildPdf(String text) throws IOException {
        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage();
            document.addPage(page);
            try (PDPageContentStream stream = new PDPageContentStream(document, page)) {
                stream.beginText();
                stream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 12);
                stream.newLineAtOffset(50, 700);
                stream.showText(text);
                stream.endText();
            }
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            document.save(out);
            return out.toByteArray();
        }
    }
}
