package com.zennyt.identity.api;

import com.zennyt.identity.application.LegalDocumentService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Documents légaux (Conditions d'utilisation, Politique de confidentialité) — publics. */
@RestController
@RequestMapping("/api/v1/legal")
@RequiredArgsConstructor
public class LegalController {

    private final LegalDocumentService legal;

    record SectionResponse(String heading, String body) {}

    record LegalDocumentResponse(String slug, String title, String lastUpdated,
                                 List<SectionResponse> sections) {
        static LegalDocumentResponse from(LegalDocumentService.Document document) {
            return new LegalDocumentResponse(document.slug(), document.title(),
                document.lastUpdated(),
                document.sections().stream()
                    .map(section -> new SectionResponse(section.heading(), section.body()))
                    .toList());
        }
    }

    @GetMapping("/{slug}")
    public LegalDocumentResponse get(@PathVariable String slug) {
        return LegalDocumentResponse.from(legal.load(slug));
    }
}
