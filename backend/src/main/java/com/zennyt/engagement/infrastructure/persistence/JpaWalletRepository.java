package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

interface JpaWalletRepository extends JpaRepository<WalletEntity, UUID> {

    /** SELECT ... FOR UPDATE : sérialise les débits concurrents d'un même portefeuille. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select wallet from WalletEntity wallet where wallet.userId = :userId")
    Optional<WalletEntity> findForUpdateByUserId(UUID userId);
}
