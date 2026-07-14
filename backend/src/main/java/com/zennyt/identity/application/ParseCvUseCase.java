package com.zennyt.identity.application;

import com.zennyt.identity.application.model.CvParseData;
import com.zennyt.identity.application.port.CvParserPort;
import com.zennyt.shared.application.exception.BadRequestException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ParseCvUseCase {
    private static final int MAX_TEXT_LENGTH = 50_000;

    private final CvParserPort parser;

    public CvParseData execute(String text, String language) {
        if (text == null || text.trim().isEmpty()) {
            throw new BadRequestException("Le texte du CV ne peut pas être vide.");
        }
        String cleanText = text.replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "");
        if (cleanText.length() > MAX_TEXT_LENGTH) {
            throw new BadRequestException(
                "Le texte du CV est trop long (limite de 50 000 caractères).");
        }
        return parser.parse(cleanText, language);
    }
}
