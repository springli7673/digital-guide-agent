-- 可观测：一轮问答一条 trace
--
-- 执行：psql -U postgres -d digital_guide -f db/migration_trace.sql

CREATE TABLE IF NOT EXISTS ai.trace (
    id              BIGSERIAL PRIMARY KEY,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    session_id      TEXT,
    question        TEXT,
    category        TEXT,
    candidates      INT,
    kb_hits         INT,
    latency_ms      INT,
    timing          JSONB,
    guard_violation TEXT,
    error           TEXT
);

COMMENT ON TABLE ai.trace IS '对话链路埋点：每轮一条，用于定位"慢在哪、检索命中几条、有没有被护栏拦"';
COMMENT ON COLUMN ai.trace.timing IS '各节点耗时（毫秒），形如 {"parse":1240,"retrieve":80}';
COMMENT ON COLUMN ai.trace.guard_violation IS '幻觉护栏发现的候选外型号/价格，为空表示干净';

CREATE INDEX IF NOT EXISTS idx_trace_created_at ON ai.trace (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trace_session ON ai.trace (session_id, created_at DESC);
