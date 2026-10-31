-- 删除 8 张历史遗留空表（2026-10-31 核对：全部 0 行，Java 代码零引用）
--
-- ai 侧 5 张是最早那版「文档 → 分块 → 会话 → 工具调用」四件套设计，
-- 后来改成扁平结构（kb_chunk 直接存标题、chat_session 存摘要+槽位）就没人回来删；
-- biz 侧 3 张是没做的功能（评价 / 收藏 / 浏览历史），收藏与浏览历史是明确决定不做的。
--
-- 执行：psql -U postgres -d digital_guide -f db/migration_cleanup_legacy.sql
-- 脚本自带保护：任何一张表里还有数据就整体报错回滚，不会误删。

BEGIN;

DO $$
DECLARE
    tbl text;
    n   bigint;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'ai.conversations', 'ai.messages', 'ai.tool_calls', 'ai.kb_documents', 'ai.kb_chunks',
        'biz.review', 'biz.favorite', 'biz.browse_history'
    ] LOOP
        IF to_regclass(tbl) IS NOT NULL THEN
            EXECUTE format('SELECT count(*) FROM %s', tbl) INTO n;
            IF n > 0 THEN
                RAISE EXCEPTION '% 里还有 % 行数据，先人工确认再删', tbl, n;
            END IF;
        END IF;
    END LOOP;
END $$;

-- 有外键的先删子表
DROP TABLE IF EXISTS ai.kb_chunks;
DROP TABLE IF EXISTS ai.kb_documents;
DROP TABLE IF EXISTS ai.messages;
DROP TABLE IF EXISTS ai.tool_calls;
DROP TABLE IF EXISTS ai.conversations;
DROP TABLE IF EXISTS biz.review;
DROP TABLE IF EXISTS biz.favorite;
DROP TABLE IF EXISTS biz.browse_history;

COMMIT;
