CREATE SCHEMA IF NOT EXISTS engagement;

CREATE TABLE engagement.actors (
    public_user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL,
    active BOOLEAN NOT NULL,
    last_event_at TIMESTAMPTZ NOT NULL,
    last_event_id UUID NOT NULL
);

CREATE TABLE engagement.conversations (
    id UUID PRIMARY KEY,
    application_id UUID NOT NULL UNIQUE,
    job_offer_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    recruiter_id UUID NOT NULL,
    job_title VARCHAR(255),
    last_message_preview VARCHAR(103) NOT NULL DEFAULT '',
    last_message_at TIMESTAMPTZ,
    candidate_unread_count INTEGER NOT NULL DEFAULT 0 CHECK (candidate_unread_count >= 0),
    recruiter_unread_count INTEGER NOT NULL DEFAULT 0 CHECK (recruiter_unread_count >= 0),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT engagement_conversation_distinct_participants CHECK (candidate_id <> recruiter_id)
);

CREATE INDEX idx_engagement_conversations_candidate
    ON engagement.conversations (candidate_id, last_message_at DESC);
CREATE INDEX idx_engagement_conversations_recruiter
    ON engagement.conversations (recruiter_id, last_message_at DESC);

CREATE TABLE engagement.messages (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES engagement.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    sender_role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    content_type VARCHAR(20) NOT NULL,
    attachment_url TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    read_at TIMESTAMPTZ
);

CREATE INDEX idx_engagement_messages_conversation_sent
    ON engagement.messages (conversation_id, sent_at DESC, id DESC);

CREATE TABLE engagement.notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    action_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_engagement_notifications_user_created
    ON engagement.notifications (user_id, created_at DESC);
CREATE INDEX idx_engagement_notifications_user_unread
    ON engagement.notifications (user_id, is_read, created_at DESC);

CREATE TABLE engagement.push_devices (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(20) NOT NULL,
    device_name VARCHAR(255),
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_engagement_push_devices_user ON engagement.push_devices (user_id);
