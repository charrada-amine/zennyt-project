package com.zennyt.games.application.usecase;

import com.zennyt.games.application.port.GamesMediaStoragePort;
import com.zennyt.games.domain.model.AdminModels.*;
import com.zennyt.games.domain.repository.GameAdminRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/** Application boundary for games administration. Scoring is intentionally absent. */
@Service
public class ManageGamesAdminUseCase {
    private final GameAdminRepository repository;
    private final GamesMediaStoragePort storage;

    public ManageGamesAdminUseCase(GameAdminRepository repository, GamesMediaStoragePort storage) {
        this.repository = repository;
        this.storage = storage;
    }

    @Transactional(readOnly = true)
    public Overview overview() { return repository.overview(); }

    @Transactional(readOnly = true)
    public List<Question> questions(ContentType type, String query) {
        return repository.questions(type, query == null ? "" : query.trim());
    }

    @Transactional
    public Question createQuestion(String externalCode, ContentType type, String prompt,
                                   String payloadJson, UUID actorId) {
        Question draft = new Question(UUID.randomUUID(), externalCode, type, prompt,
            payloadJson, Status.DRAFT, null, null, true, Instant.now());
        return repository.saveQuestion(draft, actorId);
    }

    @Transactional
    public Question createDraftFrom(UUID questionId, UUID actorId) {
        Question source = repository.findQuestion(questionId)
            .orElseThrow(() -> new IllegalArgumentException("Question introuvable : " + questionId));
        UUID authoritativeSource = source.sourceId() == null ? source.id() : source.sourceId();
        return repository.saveQuestion(new Question(UUID.randomUUID(), source.externalCode(),
            source.contentType(), source.prompt(), source.payloadJson(), Status.DRAFT,
            null, authoritativeSource, true, Instant.now()), actorId);
    }

    @Transactional
    public Question updateQuestion(UUID questionId, String externalCode, ContentType type,
                                   String prompt, String payloadJson, UUID actorId) {
        Question current = repository.findQuestion(questionId)
            .filter(Question::managed)
            .orElseThrow(() -> new IllegalArgumentException("Question administrée introuvable"));
        return repository.updateQuestion(new Question(questionId, externalCode, type, prompt,
            payloadJson, current.status(), current.bankName(), current.sourceId(), true,
            Instant.now()), actorId);
    }

    @Transactional
    public Question publishQuestion(UUID questionId, UUID actorId) {
        Question question = repository.findQuestion(questionId)
            .orElseThrow(() -> new IllegalArgumentException("Question introuvable"));
        if (!question.managed() || question.status() != Status.DRAFT) {
            throw new IllegalStateException("Seul un brouillon administré peut être publié");
        }
        return repository.changeQuestionStatus(questionId, Status.PUBLISHED, actorId);
    }

    @Transactional
    public Question archiveQuestion(UUID questionId, UUID actorId) {
        return repository.changeQuestionStatus(questionId, Status.ARCHIVED, actorId);
    }

    @Transactional
    public void deleteQuestionDraft(UUID questionId, UUID actorId) {
        repository.deleteQuestionDraft(questionId, actorId);
    }

    @Transactional(readOnly = true)
    public List<Bank> banks() { return repository.banks(); }

    @Transactional
    public Bank createBank(String code, String name, ContentType type,
                           int rotationWeight, UUID sourceBankId, UUID actorId) {
        return repository.createBank(new Bank(UUID.randomUUID(), code, name, type,
            0, rotationWeight, 1, Status.DRAFT, Instant.now()), actorId, sourceBankId);
    }

    @Transactional
    public Bank updateBank(UUID bankId, String name, int rotationWeight, UUID actorId) {
        if (name == null || name.isBlank()) throw new IllegalArgumentException("Le nom est obligatoire");
        if (rotationWeight < 0 || rotationWeight > 100) {
            throw new IllegalArgumentException("Le poids doit être compris entre 0 et 100");
        }
        return repository.updateBank(bankId, name.trim(), rotationWeight, actorId);
    }

    @Transactional(readOnly = true)
    public List<UUID> bankItems(UUID bankId) { return repository.bankItems(bankId); }

    @Transactional
    public Bank replaceBankItems(UUID bankId, List<UUID> questionIds, UUID actorId) {
        return repository.replaceBankItems(bankId, List.copyOf(questionIds), actorId);
    }

    @Transactional
    public Bank publishBank(UUID bankId, UUID actorId) {
        Bank bank = repository.findBank(bankId)
            .orElseThrow(() -> new IllegalArgumentException("Banque introuvable : " + bankId));
        if (bank.itemCount() == 0) throw new IllegalStateException("Une banque vide ne peut pas être publiée");
        return repository.publishBank(bankId, actorId);
    }

    @Transactional
    public Bank archiveBank(UUID bankId, UUID actorId) {
        return repository.archiveBank(bankId, actorId);
    }

    @Transactional
    public void deleteBankDraft(UUID bankId, UUID actorId) {
        repository.deleteBankDraft(bankId, actorId);
    }

    @Transactional(readOnly = true)
    public List<Configuration> configurations(ConfigurationKind kind) { return repository.configurations(kind); }

    @Transactional
    public Configuration createConfiguration(String gameType, ConfigurationKind kind,
                                             String valuesJson, UUID actorId) {
        return repository.createConfiguration(new Configuration(UUID.randomUUID(), gameType,
            kind, 1, valuesJson, Status.DRAFT, Instant.now()), actorId);
    }

    @Transactional
    public Configuration updateConfiguration(UUID configurationId, String gameType,
                                             ConfigurationKind kind, String valuesJson,
                                             UUID actorId) {
        return repository.updateConfiguration(new Configuration(configurationId, gameType,
            kind, 1, valuesJson, Status.DRAFT, Instant.now()), actorId);
    }

    @Transactional
    public Configuration publishConfiguration(UUID configurationId, UUID actorId) {
        return repository.publishConfiguration(configurationId, actorId);
    }

    @Transactional
    public Configuration archiveConfiguration(UUID configurationId, UUID actorId) {
        return repository.archiveConfiguration(configurationId, actorId);
    }

    @Transactional
    public void deleteConfigurationDraft(UUID configurationId, UUID actorId) {
        repository.deleteConfigurationDraft(configurationId, actorId);
    }

    @Transactional(readOnly = true)
    public List<Asset> assets() { return repository.assets(); }

    @Transactional
    public Asset uploadAsset(String gameType, byte[] content, String filename,
                             String contentType, String altText, UUID actorId) {
        String mediaType = mediaType(filename, contentType);
        GamesMediaStoragePort.StoredMedia stored = storage.upload(content, filename,
            GamesMediaStoragePort.ResourceType.IMAGE, "admin-assets");
        Asset asset = new Asset(UUID.randomUUID(), gameType, filename, mediaType,
            stored.url(), stored.publicId(), altText, Status.DRAFT, Instant.now());
        return repository.saveAsset(asset, actorId);
    }

    @Transactional
    public Asset updateAsset(UUID assetId, String gameType, String altText, UUID actorId) {
        if (gameType == null || gameType.isBlank() || gameType.length() > 48) {
            throw new IllegalArgumentException("Le type de jeu est obligatoire");
        }
        if (altText == null || altText.isBlank() || altText.length() > 2_000) {
            throw new IllegalArgumentException("Le texte alternatif est obligatoire");
        }
        return repository.updateAsset(assetId, gameType.trim().toUpperCase(Locale.ROOT),
            altText.trim(), actorId);
    }

    @Transactional
    public Asset publishAsset(UUID assetId, UUID actorId) {
        return repository.changeAssetStatus(assetId, Status.PUBLISHED, actorId);
    }

    @Transactional
    public Asset archiveAsset(UUID assetId, UUID actorId) {
        return repository.changeAssetStatus(assetId, Status.ARCHIVED, actorId);
    }

    @Transactional
    public void deleteAssetDraft(UUID assetId, UUID actorId) {
        Asset asset = repository.findAsset(assetId)
            .filter(candidate -> candidate.status() == Status.DRAFT)
            .orElseThrow(() -> new IllegalStateException("Seul un asset en brouillon peut être supprimé"));
        storage.delete(asset.publicId(), GamesMediaStoragePort.ResourceType.IMAGE);
        repository.deleteAssetDraft(assetId, actorId);
    }

    @Transactional(readOnly = true)
    public AssetContent assetContent(UUID assetId) {
        Asset asset = repository.findAsset(assetId)
            .orElseThrow(() -> new IllegalArgumentException("Asset introuvable"));
        if (!asset.publicId().startsWith("local/")) {
            throw new IllegalStateException("Le contenu distant est servi directement par le CDN");
        }
        return new AssetContent(asset, storage.read(asset.publicId()));
    }

    @Transactional(readOnly = true)
    public AssetContent publishedAssetContent(UUID assetId) {
        Asset asset = repository.findAsset(assetId)
            .filter(candidate -> candidate.status() == Status.PUBLISHED)
            .orElseThrow(() -> new NotFoundException("Asset publié introuvable"));
        if (!asset.publicId().startsWith("local/")) {
            throw new IllegalStateException("Le contenu distant est servi directement par le CDN");
        }
        return new AssetContent(asset, storage.read(asset.publicId()));
    }

    @Transactional(readOnly = true)
    public List<AuditEntry> auditEntries() { return repository.auditEntries(); }

    public record AssetContent(Asset asset, byte[] bytes) {}

    private static String mediaType(String filename, String contentType) {
        String lower = filename.toLowerCase(Locale.ROOT);
        if ((lower.endsWith(".png")) && "image/png".equals(contentType)) return "PNG";
        if ((lower.endsWith(".svg")) && "image/svg+xml".equals(contentType)) return "SVG";
        throw new IllegalArgumentException("Le fichier doit être un PNG ou SVG cohérent avec son type MIME");
    }
}
