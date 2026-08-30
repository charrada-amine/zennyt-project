package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.model.AdminModels.*;
import com.zennyt.games.domain.model.GameRuntimeSnapshot;
import com.zennyt.games.domain.vo.GameType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GameAdminRepository {
    GameRuntimeSnapshot runtimeSnapshot(GameType gameType);
    Overview overview();
    List<Question> questions(ContentType contentType, String query);
    Optional<Question> findQuestion(UUID questionId);
    Question saveQuestion(Question question, UUID actorId);
    Question updateQuestion(Question question, UUID actorId);
    Question changeQuestionStatus(UUID questionId, Status status, UUID actorId);
    void deleteQuestionDraft(UUID questionId, UUID actorId);
    List<Bank> banks();
    Bank createBank(Bank bank, UUID actorId, UUID sourceBankId);
    Optional<Bank> findBank(UUID bankId);
    Bank updateBank(UUID bankId, String name, int rotationWeight, UUID actorId);
    List<UUID> bankItems(UUID bankId);
    Bank replaceBankItems(UUID bankId, List<UUID> questionIds, UUID actorId);
    Bank publishBank(UUID bankId, UUID actorId);
    Bank archiveBank(UUID bankId, UUID actorId);
    void deleteBankDraft(UUID bankId, UUID actorId);
    List<Configuration> configurations(ConfigurationKind kind);
    Configuration createConfiguration(Configuration configuration, UUID actorId);
    Configuration updateConfiguration(Configuration configuration, UUID actorId);
    Configuration publishConfiguration(UUID configurationId, UUID actorId);
    Configuration archiveConfiguration(UUID configurationId, UUID actorId);
    void deleteConfigurationDraft(UUID configurationId, UUID actorId);
    List<Asset> assets();
    Optional<Asset> findAsset(UUID assetId);
    Asset saveAsset(Asset asset, UUID actorId);
    Asset updateAsset(UUID assetId, String gameType, String altText, UUID actorId);
    Asset changeAssetStatus(UUID assetId, Status status, UUID actorId);
    void deleteAssetDraft(UUID assetId, UUID actorId);
    List<AuditEntry> auditEntries();
}
