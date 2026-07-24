ALTER TABLE engagement.actors ADD COLUMN display_name VARCHAR(255);
ALTER TABLE engagement.actors ADD COLUMN photo_url TEXT;

CREATE TABLE engagement.posts (
    id UUID PRIMARY KEY,
    author_id UUID NOT NULL,
    visibility VARCHAR(20) NOT NULL,
    content TEXT,
    poll_id UUID,
    poll_question TEXT,
    poll_duration VARCHAR(100),
    comments_count INTEGER NOT NULL DEFAULT 0 CHECK (comments_count >= 0),
    created_at TIMESTAMPTZ NOT NULL,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_engagement_posts_created ON engagement.posts (created_at DESC, id DESC);
CREATE INDEX idx_engagement_posts_author ON engagement.posts (author_id, created_at DESC);

CREATE TABLE engagement.post_media (
    id UUID PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES engagement.posts(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    url TEXT NOT NULL
);

CREATE TABLE engagement.poll_options (
    id UUID PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES engagement.posts(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    vote_count INTEGER NOT NULL DEFAULT 0 CHECK (vote_count >= 0)
);

CREATE TABLE engagement.post_likes (
    post_id UUID NOT NULL REFERENCES engagement.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (post_id, user_id)
);

CREATE TABLE engagement.poll_votes (
    post_id UUID NOT NULL REFERENCES engagement.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    option_id UUID NOT NULL REFERENCES engagement.poll_options(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (post_id, user_id)
);

CREATE TABLE engagement.comments (
    id UUID PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES engagement.posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_engagement_comments_post ON engagement.comments (post_id, created_at, id);

CREATE TABLE engagement.user_post_preferences (
    user_id UUID PRIMARY KEY,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE engagement.hidden_posts (
    user_id UUID NOT NULL REFERENCES engagement.user_post_preferences(user_id) ON DELETE CASCADE,
    post_id UUID NOT NULL,
    PRIMARY KEY (user_id, post_id)
);

CREATE TABLE engagement.blocked_authors (
    user_id UUID NOT NULL REFERENCES engagement.user_post_preferences(user_id) ON DELETE CASCADE,
    author_id UUID NOT NULL,
    PRIMARY KEY (user_id, author_id)
);

CREATE TABLE engagement.friendships (
    user_id UUID NOT NULL,
    friend_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, friend_id),
    CONSTRAINT engagement_friendship_distinct_users CHECK (user_id <> friend_id)
);

CREATE TABLE engagement.call_sessions (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES engagement.conversations(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    initiator_id UUID NOT NULL,
    counterpart_id UUID NOT NULL,
    webrtc_offer TEXT NOT NULL,
    webrtc_answer TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_engagement_calls_conversation ON engagement.call_sessions (conversation_id, started_at DESC);

CREATE TABLE engagement.help_chats (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NOT NULL,
    last_message_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_engagement_help_chats_user ON engagement.help_chats (user_id, last_message_at DESC);

CREATE TABLE engagement.help_messages (
    id UUID PRIMARY KEY,
    help_chat_id UUID NOT NULL REFERENCES engagement.help_chats(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    from_user BOOLEAN NOT NULL
);

CREATE INDEX idx_engagement_help_messages_chat ON engagement.help_messages (help_chat_id, sent_at, id);
