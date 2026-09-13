package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.Wallet;
import com.zennyt.engagement.domain.model.WalletCard;

/** Vue combinée solde + carte, pour l'écran Wallet. */
public record WalletView(Wallet wallet, WalletCard card) {
}
