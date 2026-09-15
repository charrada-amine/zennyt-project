package com.zennyt.engagement.domain.vo;

/** Sens d'une écriture du portefeuille. */
public enum WalletTransactionKind {
    /** Crédit (bonus de parrainage, remboursement…). */
    CREDIT,
    /** Débit (paiement d'un service). */
    DEBIT,
    /** Retrait vers la banque. */
    WITHDRAWAL
}
