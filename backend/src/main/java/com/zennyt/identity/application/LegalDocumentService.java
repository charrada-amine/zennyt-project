package com.zennyt.identity.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

/**
 * Documents légaux servis depuis le classpath (`resources/legal/<slug>.json`).
 * Le contenu est ainsi modifiable sans publier une nouvelle version de l'app.
 */
@Service
public class LegalDocumentService {

    private final ObjectMapper mapper;

    public LegalDocumentService(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    public record Section(String heading, String body) {}

    public record Document(String slug, String title, String lastUpdated, List<Section> sections) {}

    public Document load(String slug) {
        if (slug == null || !slug.matches("[a-z0-9-]+")) {
            throw new NotFoundException("Document introuvable");
        }
        ClassPathResource resource = new ClassPathResource("legal/" + slug + ".json");
        if (!resource.exists()) {
            throw new NotFoundException("Document introuvable : " + slug);
        }
        try (InputStream in = resource.getInputStream()) {
            return mapper.readValue(in, Document.class);
        } catch (IOException e) {
            throw new IllegalStateException("Document légal illisible : " + slug, e);
        }
    }
}
