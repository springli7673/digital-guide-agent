-- RAG：知识库语料入库（pgvector）
--
-- 执行：psql -U postgres -d digital_guide -f db/migration_rag.sql
--
-- 两个扩展：
--   vector    —— pgvector，存 1024 维 bge-m3 向量
--   pg_trgm   —— 三元组相似度，给"关键词路"用（PG 自带分词器不认识中文，
--                所以不用 tsvector；等量级上去了再考虑 zhparser 或 ES+IK）

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS ai.kb_chunk (
    id          BIGSERIAL PRIMARY KEY,
    doc_title   TEXT        NOT NULL,
    heading     TEXT,
    content     TEXT        NOT NULL,
    embedding   vector(1024),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai.kb_chunk IS '选购知识库分块：一篇文章按小节切成多块，每块一条向量';
COMMENT ON COLUMN ai.kb_chunk.doc_title IS '文档标题，入库时按它整篇替换（幂等）';
COMMENT ON COLUMN ai.kb_chunk.heading IS '所属小节标题，用于回答里的引用角标';

-- 向量路：HNSW + 余弦距离（pgvector >= 0.5 才有 hnsw）
CREATE INDEX IF NOT EXISTS idx_kb_chunk_embedding
    ON ai.kb_chunk USING hnsw (embedding vector_cosine_ops);

-- 关键词路的 ILIKE/相似度过滤
CREATE INDEX IF NOT EXISTS idx_kb_chunk_title ON ai.kb_chunk (doc_title);
CREATE INDEX IF NOT EXISTS idx_kb_chunk_content_trgm
    ON ai.kb_chunk USING gin (content gin_trgm_ops);
