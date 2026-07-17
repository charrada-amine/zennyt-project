package com.zennyt.recruitment.domain.vo;

/**
 * Fourchette de salaire — value object immuable.
 *
 * <p>Pas d'annotation JPA ni Spring : c'est du domaine pur.
 * L'infrastructure mappe vers/depuis les colonnes SQL.
 */
public record SalaryRange(double min, double max, String currency) {

    public SalaryRange {
        if (min < 0) throw new IllegalArgumentException("Le salaire minimum ne peut pas être négatif");
        if (max < min) throw new IllegalArgumentException("Le salaire maximum doit être >= minimum");
        if (currency == null || currency.isBlank()) throw new IllegalArgumentException("La devise est obligatoire");
    }
}
