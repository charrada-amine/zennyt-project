package com.zennyt.recruitment.domain.vo;

/**
 * Montant monétaire — value object immuable.
 *
 * <p>Utilisé pour les paiements (amount, tax, total).
 */
public record Money(double amount, String currency) {

    public Money {
        if (amount < 0) throw new IllegalArgumentException("Le montant ne peut pas être négatif");
        if (currency == null || currency.isBlank()) throw new IllegalArgumentException("La devise est obligatoire");
    }

    /** Additionner deux montants (même devise). */
    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("Impossible d'additionner des devises différentes");
        }
        return new Money(this.amount + other.amount, this.currency);
    }
}
