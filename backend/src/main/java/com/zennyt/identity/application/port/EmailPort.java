package com.zennyt.identity.application.port;

/**
 * Port d'envoi d'e-mails transactionnels.
 *
 * <p>L'application dépend de cette abstraction, pas de Resend. L'adaptateur
 * concret (et le rendu HTML) vit dans la couche infrastructure.
 */
public interface EmailPort {

    /**
     * Envoie le code OTP de réinitialisation de mot de passe.
     *
     * @param toEmail       destinataire
     * @param recipientName prénom/nom pour personnaliser le message (peut être vide)
     * @param code          code à usage unique en clair (jamais persisté en clair)
     */
    void sendPasswordResetCode(String toEmail, String recipientName, String code);

    /**
     * Envoie le code OTP de confirmation d'un changement de coordonnée.
     *
     * <p>Livraison provisoire par e-mail pour les changements d'e-mail ET de
     * téléphone : le canal SMS n'est pas encore intégré. Le libellé
     * {@code targetLabel} indique la valeur en cours de confirmation.
     *
     * @param toEmail       destinataire (nouvelle adresse, ou adresse du compte
     *                      pour un changement de téléphone)
     * @param recipientName prénom/nom pour personnaliser le message
     * @param code          code à usage unique en clair (jamais persisté en clair)
     * @param targetLabel   valeur confirmée (ex. nouvelle adresse ou téléphone)
     */
    void sendAccountChangeCode(String toEmail, String recipientName, String code, String targetLabel);
}
