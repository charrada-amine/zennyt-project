package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.HelpChatRating;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.Comment;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "help_chats", schema = "engagement",
    indexes = @Index(name = "idx_engagement_help_chats_user", columnList = "user_id, last_message_at DESC"))
@Check(name = "help_chats_rating_date_coherente", constraints = "(rating IS NULL) = (rated_at IS NULL)")
@Check(name = "help_chats_rating_valide", constraints = "rating IS NULL OR rating IN ('POOR', 'OK', 'GREAT')")
class HelpChatEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID userId;
    @Column(nullable = false) private String title;
    @Column(nullable = false) private String subtitle;
    private Instant lastMessageAt;
    // Apostrophes doublées : Hibernate 6.5 insère le texte de @Comment tel quel entre quotes SQL.
    @Comment("Appreciation de l''utilisateur sur l''echange : POOR, OK ou GREAT.")
    @Enumerated(EnumType.STRING) @Column(length = Length.LONG32) private HelpChatRating rating;
    @Comment("Commentaire libre facultatif, saisi apres la note.")
    @Column(length = Length.LONG32) private String ratingComment;
    private Instant ratedAt;
    @Version @ColumnDefault("0") private long version;
    protected HelpChatEntity() {}
    HelpChatEntity(UUID id, UUID userId, String title, String subtitle, Instant lastMessageAt) {
        this.id = id; this.userId = userId; this.title = title;
        this.subtitle = subtitle; this.lastMessageAt = lastMessageAt;
    }
    void update(Instant value) { this.lastMessageAt = value; }
    void applyRating(HelpChatRating value, String comment, Instant at) {
        this.rating = value; this.ratingComment = comment; this.ratedAt = at;
    }
    UUID getId() { return id; } UUID getUserId() { return userId; }
    String getTitle() { return title; } String getSubtitle() { return subtitle; }
    Instant getLastMessageAt() { return lastMessageAt; }
    HelpChatRating getRating() { return rating; }
    String getRatingComment() { return ratingComment; }
    Instant getRatedAt() { return ratedAt; }
}
