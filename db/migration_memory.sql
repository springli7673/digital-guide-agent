-- 对话记忆：消息表 + 会话状态（摘要 / 槽位）
--
-- 执行：psql -U postgres -d digital_guide -f db/migration_memory.sql

CREATE TABLE IF NOT EXISTS ai.chat_message (
    id          BIGSERIAL PRIMARY KEY,
    session_id  TEXT        NOT NULL,
    role        TEXT        NOT NULL,          -- user / assistant
    content     TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai.chat_message IS '会话消息；超出滑动窗口的部分会被摘要压缩后删除';

CREATE TABLE IF NOT EXISTS ai.chat_session (
    session_id  TEXT PRIMARY KEY,
    summary     TEXT,                          -- 被压缩掉的历史的摘要
    slots       JSONB,                         -- 最近一次确认的意图槽位（槽位锚点）
    turns       INT         NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai.chat_session IS '会话状态：摘要 + 槽位锚点，用来在多轮里不丢上下文';
COMMENT ON COLUMN ai.chat_session.slots IS '最近一次 Intent 的 JSON；用户只说"便宜点"时靠它继承预算和偏好';

CREATE INDEX IF NOT EXISTS idx_chat_message_session ON ai.chat_message (session_id, id);
