package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.AccountChangeCode;
import com.zennyt.identity.domain.model.AccountChangeType;

import java.util.Optional;

public interface AccountChangeCodeRepository {
    AccountChangeCode save(AccountChangeCode code);

    /** Dernier code non consommé du compte pour ce type de changement. */
    Optional<AccountChangeCode> findLatestActiveByUserIdAndType(Long userId, AccountChangeType type);

    /** Consomme tous les codes actifs du compte pour ce type (avant d'en émettre un nouveau). */
    void invalidateAllForUserAndType(Long userId, AccountChangeType type);
}
