package com.zennyt.games.api;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.application.usecase.ManageGamesAdminUseCase;
import com.zennyt.games.domain.model.AdminConfigurationSchemaRegistry;
import com.zennyt.games.domain.model.AdminConfigurationSchemaRegistry.ValueType;
import com.zennyt.games.domain.model.AdminModels.*;
import com.zennyt.games.domain.vo.GameType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** ADMIN-only HTTP adapter for the games bounded context. */
@RestController
@RequestMapping("/api/v1/games/admin")
@PreAuthorize("hasRole('ADMIN')")
public class GamesAdminController {
    private static final long MAX_ASSET_BYTES = 5L * 1024L * 1024L;
    private final ManageGamesAdminUseCase admin;
    private final ObjectMapper objectMapper;

    public GamesAdminController(ManageGamesAdminUseCase admin, ObjectMapper objectMapper) {
        this.admin = admin;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/overview")
    public OverviewResponse overview() { return OverviewResponse.from(admin.overview()); }

    @GetMapping("/questions")
    public List<QuestionResponse> questions(
            @RequestParam(required = false) ContentType contentType,
            @RequestParam(required = false, defaultValue = "") String query) {
        return admin.questions(contentType, query).stream().map(this::questionResponse).toList();
    }

    @PostMapping("/questions")
    @ResponseStatus(HttpStatus.CREATED)
    public QuestionResponse createQuestion(@AuthenticationPrincipal Jwt jwt,
                                           @Valid @RequestBody QuestionWrite request) {
        return questionResponse(admin.createQuestion(request.externalCode(), request.contentType(),
            request.prompt(), json(request.payload()), actor(jwt)));
    }

    @PutMapping("/questions/{questionId}")
    public QuestionResponse updateQuestion(@AuthenticationPrincipal Jwt jwt,
                                           @PathVariable UUID questionId,
                                           @Valid @RequestBody QuestionWrite request) {
        return questionResponse(admin.updateQuestion(questionId, request.externalCode(),
            request.contentType(), request.prompt(), json(request.payload()), actor(jwt)));
    }

    @PostMapping("/questions/{questionId}/draft")
    @ResponseStatus(HttpStatus.CREATED)
    public QuestionResponse createQuestionDraft(@AuthenticationPrincipal Jwt jwt,
                                                @PathVariable UUID questionId) {
        return questionResponse(admin.createDraftFrom(questionId, actor(jwt)));
    }

    @PostMapping("/questions/{questionId}/publish")
    public QuestionResponse publishQuestion(@AuthenticationPrincipal Jwt jwt,
                                            @PathVariable UUID questionId) {
        return questionResponse(admin.publishQuestion(questionId, actor(jwt)));
    }

    @PostMapping("/questions/{questionId}/archive")
    public QuestionResponse archiveQuestion(@AuthenticationPrincipal Jwt jwt,
                                            @PathVariable UUID questionId) {
        return questionResponse(admin.archiveQuestion(questionId, actor(jwt)));
    }

    @DeleteMapping("/questions/{questionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteQuestion(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID questionId) {
        admin.deleteQuestionDraft(questionId, actor(jwt));
    }

    @GetMapping("/banks")
    public List<BankResponse> banks() { return admin.banks().stream().map(BankResponse::from).toList(); }

    @PostMapping("/banks")
    @ResponseStatus(HttpStatus.CREATED)
    public BankResponse createBank(@AuthenticationPrincipal Jwt jwt,
                                   @Valid @RequestBody BankWrite request) {
        return BankResponse.from(admin.createBank(request.code(), request.name(), request.contentType(),
            request.rotationWeight(), request.sourceBankId(), actor(jwt)));
    }

    @PutMapping("/banks/{bankId}")
    public BankResponse updateBank(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID bankId,
                                   @Valid @RequestBody BankUpdate request) {
        return BankResponse.from(admin.updateBank(bankId, request.name(),
            request.rotationWeight(), actor(jwt)));
    }

    @GetMapping("/banks/{bankId}/items")
    public BankItemsResponse bankItems(@PathVariable UUID bankId) {
        return new BankItemsResponse(admin.bankItems(bankId));
    }

    @PutMapping("/banks/{bankId}/items")
    public BankResponse replaceBankItems(@AuthenticationPrincipal Jwt jwt,
                                         @PathVariable UUID bankId,
                                         @Valid @RequestBody BankItemsResponse request) {
        return BankResponse.from(admin.replaceBankItems(bankId, request.questionIds(), actor(jwt)));
    }

    @PostMapping("/banks/{bankId}/publish")
    public BankResponse publishBank(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID bankId) {
        return BankResponse.from(admin.publishBank(bankId, actor(jwt)));
    }

    @PostMapping("/banks/{bankId}/archive")
    public BankResponse archiveBank(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID bankId) {
        return BankResponse.from(admin.archiveBank(bankId, actor(jwt)));
    }

    @DeleteMapping("/banks/{bankId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteBank(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID bankId) {
        admin.deleteBankDraft(bankId, actor(jwt));
    }

    @GetMapping("/configurations")
    public List<ConfigurationResponse> configurations(
            @RequestParam(required = false) ConfigurationKind kind) {
        return admin.configurations(kind).stream().map(this::configurationResponse).toList();
    }

    @GetMapping("/configuration-schemas")
    public List<ConfigurationSchemaResponse> configurationSchemas() {
        return admin.configurationSchemas().stream().map(ConfigurationSchemaResponse::from).toList();
    }

    @PostMapping("/configurations")
    @ResponseStatus(HttpStatus.CREATED)
    public ConfigurationResponse createConfiguration(@AuthenticationPrincipal Jwt jwt,
                                                      @Valid @RequestBody ConfigurationWrite request) {
        return configurationResponse(admin.createConfiguration(request.gameType(), request.kind(),
            json(request.values()), actor(jwt)));
    }

    @PutMapping("/configurations/{configurationId}")
    public ConfigurationResponse updateConfiguration(@AuthenticationPrincipal Jwt jwt,
                                                      @PathVariable UUID configurationId,
                                                      @Valid @RequestBody ConfigurationWrite request) {
        return configurationResponse(admin.updateConfiguration(configurationId, request.gameType(),
            request.kind(), json(request.values()), actor(jwt)));
    }

    @PostMapping("/configurations/{configurationId}/publish")
    public ConfigurationResponse publishConfiguration(@AuthenticationPrincipal Jwt jwt,
                                                       @PathVariable UUID configurationId) {
        return configurationResponse(admin.publishConfiguration(configurationId, actor(jwt)));
    }

    @PostMapping("/configurations/{configurationId}/archive")
    public ConfigurationResponse archiveConfiguration(@AuthenticationPrincipal Jwt jwt,
                                                       @PathVariable UUID configurationId) {
        return configurationResponse(admin.archiveConfiguration(configurationId, actor(jwt)));
    }

    @DeleteMapping("/configurations/{configurationId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteConfiguration(@AuthenticationPrincipal Jwt jwt,
                                    @PathVariable UUID configurationId) {
        admin.deleteConfigurationDraft(configurationId, actor(jwt));
    }

    @GetMapping("/assets")
    public List<AssetResponse> assets() { return admin.assets().stream().map(AssetResponse::from).toList(); }

    @PostMapping(value = "/assets", consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public AssetResponse uploadAsset(@AuthenticationPrincipal Jwt jwt,
                                     @RequestPart("file") MultipartFile file,
                                     @RequestParam("gameType") @NotBlank String gameType,
                                     @RequestParam("altText") @NotBlank String altText) throws IOException {
        if (file.isEmpty() || file.getSize() > MAX_ASSET_BYTES) {
            throw new IllegalArgumentException("L'asset doit faire entre 1 octet et 10 Mo");
        }
        String filename = file.getOriginalFilename() == null ? "asset" : file.getOriginalFilename();
        return AssetResponse.from(admin.uploadAsset(gameType, file.getBytes(), filename,
            file.getContentType(), altText, actor(jwt)));
    }

    @PutMapping("/assets/{assetId}")
    public AssetResponse updateAsset(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID assetId,
                                     @Valid @RequestBody AssetUpdate request) {
        return AssetResponse.from(admin.updateAsset(assetId, request.gameType(),
            request.altText(), actor(jwt)));
    }

    @GetMapping("/assets/{assetId}")
    public ResponseEntity<byte[]> assetContent(@PathVariable UUID assetId) {
        ManageGamesAdminUseCase.AssetContent content = admin.assetContent(assetId);
        String mediaType = "PNG".equals(content.asset().mediaType())
            ? MediaType.IMAGE_PNG_VALUE : "image/svg+xml";
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(mediaType))
            .header("Cache-Control", "private, max-age=300")
            .body(content.bytes());
    }

    @DeleteMapping("/assets/{assetId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAsset(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID assetId) {
        admin.deleteAssetDraft(assetId, actor(jwt));
    }

    @PostMapping("/assets/{assetId}/publish")
    public AssetResponse publishAsset(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID assetId) {
        return AssetResponse.from(admin.publishAsset(assetId, actor(jwt)));
    }

    @PostMapping("/assets/{assetId}/archive")
    public AssetResponse archiveAsset(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID assetId) {
        return AssetResponse.from(admin.archiveAsset(assetId, actor(jwt)));
    }

    @GetMapping("/releases")
    public List<AuditResponse> releases() {
        return admin.auditEntries().stream().map(this::auditResponse).toList();
    }

    private QuestionResponse questionResponse(Question question) {
        return new QuestionResponse(question.id(), question.externalCode(), question.contentType(),
            question.prompt(), readJson(question.payloadJson()), question.status(), question.bankName(),
            question.sourceId(), question.managed(), question.updatedAt());
    }

    private ConfigurationResponse configurationResponse(Configuration configuration) {
        return new ConfigurationResponse(configuration.id(), configuration.gameType(),
            configuration.kind(), configuration.version(), readJson(configuration.valuesJson()), false,
            configuration.status(), configuration.updatedAt());
    }

    private AuditResponse auditResponse(AuditEntry entry) {
        return new AuditResponse(entry.id(), entry.action(), entry.entityType(), entry.entityId(),
            entry.actorId(), readJson(entry.detailsJson()), entry.createdAt());
    }

    private String json(Map<String, Object> value) {
        try { return objectMapper.writeValueAsString(value); }
        catch (JsonProcessingException exception) { throw new IllegalArgumentException("JSON invalide", exception); }
    }

    private JsonNode readJson(String value) {
        try { return objectMapper.readTree(value); }
        catch (JsonProcessingException exception) { throw new IllegalStateException("JSON persisté invalide", exception); }
    }

    private static UUID actor(Jwt jwt) { return UUID.fromString(jwt.getSubject()); }

    public record OverviewResponse(long questionCount, long publishedBankCount,
                                   long draftCount, long assetCount) {
        static OverviewResponse from(Overview value) {
            return new OverviewResponse(value.questionCount(), value.publishedBankCount(),
                value.draftCount(), value.assetCount());
        }
    }

    public record QuestionWrite(@NotBlank String externalCode, @NotNull ContentType contentType,
                                @NotBlank String prompt, @NotNull Map<String, Object> payload) {}
    public record QuestionResponse(UUID id, String externalCode, ContentType contentType,
                                   String prompt, JsonNode payload, Status status,
                                   String bankName, UUID sourceId, boolean managed,
                                   Instant updatedAt) {}
    public record BankWrite(@NotBlank String code, @NotBlank String name,
                            @NotNull ContentType contentType,
                            @Min(0) @Max(100) int rotationWeight, UUID sourceBankId) {}
    public record BankUpdate(@NotBlank String name,
                             @Min(0) @Max(100) int rotationWeight) {}
    public record BankItemsResponse(@NotNull List<@NotNull UUID> questionIds) {}
    public record BankResponse(UUID id, String code, String name, ContentType contentType,
                               int itemCount, int rotationWeight, int version,
                               Status status, Instant updatedAt) {
        static BankResponse from(Bank bank) {
            return new BankResponse(bank.id(), bank.code(), bank.name(), bank.contentType(),
                bank.itemCount(), bank.rotationWeight(), bank.version(), bank.status(), bank.updatedAt());
        }
    }
    public record ConfigurationWrite(@NotBlank String gameType, @NotNull ConfigurationKind kind,
                                     @NotNull Map<String, Object> values) {}
    public record ConfigurationResponse(UUID id, String gameType, ConfigurationKind kind,
                                        int version, JsonNode values,
                                        boolean protectedScoring, Status status, Instant updatedAt) {}
    public record ConfigurationFieldResponse(String key, String label, String description,
                                             ValueType valueType, boolean required,
                                             Object defaultValue, Integer minimum, Integer maximum,
                                             List<String> options) {
        static ConfigurationFieldResponse from(AdminConfigurationSchemaRegistry.Field field) {
            return new ConfigurationFieldResponse(field.key(), field.label(), field.description(),
                field.valueType(), field.required(), field.defaultValue(), field.minimum(),
                field.maximum(), field.options());
        }
    }
    public record ConfigurationSchemaResponse(GameType gameType, ConfigurationKind kind,
                                              List<ConfigurationFieldResponse> fields) {
        static ConfigurationSchemaResponse from(AdminConfigurationSchemaRegistry.Schema schema) {
            return new ConfigurationSchemaResponse(schema.gameType(), schema.kind(),
                schema.fields().stream().map(ConfigurationFieldResponse::from).toList());
        }
    }
    public record AssetUpdate(@NotBlank String gameType, @NotBlank String altText) {}
    public record AssetResponse(UUID id, String gameType, String filename, String mediaType,
                                String url, String altText, Status status, Instant createdAt) {
        static AssetResponse from(Asset asset) {
            String deliveryUrl = asset.url().startsWith("local://")
                ? (asset.status() == Status.PUBLISHED
                    ? "/api/v1/games/assets/" + asset.id()
                    : "/api/v1/games/admin/assets/" + asset.id())
                : asset.url();
            return new AssetResponse(asset.id(), asset.gameType(), asset.filename(), asset.mediaType(),
                deliveryUrl, asset.altText(), asset.status(), asset.createdAt());
        }
    }
    public record AuditResponse(UUID id, String action, String entityType, UUID entityId,
                                UUID actorId, JsonNode details, Instant createdAt) {}
}
