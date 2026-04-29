-- ============================================================
-- DBA Monitoring Sorguları — pg_stat_* view'ları
-- ============================================================

-- 1. Aktif bağlantılar ve sorgular
SELECT pid, usename, application_name, state,
       ROUND(EXTRACT(EPOCH FROM (now() - query_start))::numeric, 2) AS duration_sec,
       LEFT(query, 80) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
  AND pid != pg_backend_pid()
ORDER BY duration_sec DESC NULLS LAST;

-- 2. Long-running sorgular (5 saniyeden uzun)
SELECT pid, usename, state,
       ROUND(EXTRACT(EPOCH FROM (now() - query_start))::numeric, 1) AS duration_sec,
       wait_event_type, wait_event,
       query
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < now() - interval '5 seconds'
  AND pid != pg_backend_pid();

-- 3. Tablo başına seq scan vs index scan (sağlıksız tablolar)
SELECT relname AS table_name,
       seq_scan, idx_scan,
       CASE WHEN seq_scan > 0
            THEN ROUND(idx_scan::numeric / seq_scan, 2)
            ELSE NULL END AS idx_to_seq_ratio,
       n_live_tup AS live_rows,
       n_dead_tup AS dead_rows,
       ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS bloat_pct
FROM pg_stat_user_tables
WHERE schemaname = 'ecommerce'
ORDER BY seq_scan DESC;

-- 4. Cache hit oranı (>99% olmalı)
SELECT relname AS table_name,
       heap_blks_read  AS disk_reads,
       heap_blks_hit   AS cache_hits,
       ROUND(100.0 * heap_blks_hit /
             NULLIF(heap_blks_hit + heap_blks_read, 0), 2) AS cache_hit_pct
FROM pg_statio_user_tables
WHERE schemaname = 'ecommerce'
ORDER BY heap_blks_read DESC;

-- 5. Veritabanı genel cache hit oranı
SELECT datname,
       blks_read AS disk_reads,
       blks_hit  AS cache_hits,
       ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_pct,
       xact_commit   AS commits,
       xact_rollback AS rollbacks,
       deadlocks
FROM pg_stat_database
WHERE datname = 'ecommerce_db';

-- 6. Tablo şişmesi (bloat) — VACUUM ihtiyacı olan tablolar
SELECT relname AS table_name,
       n_live_tup, n_dead_tup,
       last_vacuum, last_autovacuum,
       last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'ecommerce'
ORDER BY n_dead_tup DESC;

-- 7. Kilit bekleyen sorgular
SELECT
    blocked.pid        AS blocked_pid,
    blocked.query      AS blocked_query,
    blocking.pid       AS blocking_pid,
    blocking.query     AS blocking_query
FROM pg_stat_activity AS blocked
JOIN pg_stat_activity AS blocking
  ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0;

-- 8. Bağlantı havuzu kullanımı
SELECT count(*) AS total_connections,
       count(*) FILTER (WHERE state = 'active')  AS active,
       count(*) FILTER (WHERE state = 'idle')    AS idle,
       count(*) FILTER (WHERE state = 'idle in transaction') AS idle_in_tx,
       (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections
FROM pg_stat_activity
WHERE datname = 'ecommerce_db';
