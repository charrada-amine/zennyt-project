package com.zennyt.identity.infrastructure.email;

import com.resend.Resend;
import com.resend.core.exception.ResendException;
import com.resend.services.emails.model.CreateEmailOptions;
import com.zennyt.identity.application.port.EmailPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Adaptateur Resend du {@link EmailPort}. Construit le rendu HTML et délègue
 * l'envoi au client Resend. Toute erreur d'envoi est remontée en exception
 * non vérifiée afin d'être traitée par la couche applicative/web.
 */
@Component
public class ResendEmailAdapter implements EmailPort {

    private final Resend resend;
    private final String fromEmail;

    public ResendEmailAdapter(Resend resend,
                              @Value("${resend.from-email:}") String fromEmail) {
        this.resend = resend;
        this.fromEmail = fromEmail;
    }

    @Override
    public void sendPasswordResetCode(String toEmail, String recipientName, String code) {
        String greeting = (recipientName == null || recipientName.isBlank())
            ? "Bonjour" : "Bonjour " + recipientName;
        String html = """
            <div style="font-family:Arial,sans-serif;font-size:15px;color:#1a1a1a">
              <p>%s,</p>
              <p>Voici votre code de réinitialisation de mot de passe :</p>
              <p style="font-size:28px;font-weight:bold;letter-spacing:4px;margin:16px 0">%s</p>
              <p>Ce code expire dans quelques minutes. Si vous n'êtes pas à l'origine de
                 cette demande, ignorez cet e-mail.</p>
              <p>— L'équipe Zennyt</p>
            </div>
            """.formatted(greeting, code);

        CreateEmailOptions options = CreateEmailOptions.builder()
            .from(fromEmail)
            .to(toEmail)
            .subject("Votre code de réinitialisation Zennyt")
            .html(html)
            .build();

        try {
            resend.emails().send(options);
        } catch (ResendException e) {
            throw new EmailDeliveryException("Échec de l'envoi de l'e-mail de réinitialisation", e);
        }
    }

    /** Erreur d'envoi d'e-mail (infrastructure). */
    public static class EmailDeliveryException extends RuntimeException {
        public EmailDeliveryException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
