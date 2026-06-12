/**
 * Bounded Context <b>Engagement</b>.
 *
 * <p>Responsabilités : messagerie candidat/recruteur, notifications, temps réel
 * (Azure SignalR), envoi multicanal (Azure Communication Services, Notification Hubs).
 *
 * <p>Écoute notamment {@code ApplicationSubmittedEvent} (Recruitment) pour créer
 * la conversation et notifier. Propriété : Squad Engagement.
 */
package com.zennyt.engagement;
