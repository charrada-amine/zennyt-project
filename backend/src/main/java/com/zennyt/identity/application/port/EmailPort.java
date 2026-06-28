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
}
