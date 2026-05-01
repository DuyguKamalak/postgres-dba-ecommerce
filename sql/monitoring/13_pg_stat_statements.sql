-- pg_stat_statements — Yavaş Sorgu Analizi
-- Önce extension'ı etkinleştir:
--   ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
--   (ardından PostgreSQL restart gerekir)
--   CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SET search_path TO ecommerce;

-- ============================================================
-- 1. En Yavaş 10 Sorgu (Ortalama Süreye Göre)
-- ============================================================
SELECT
    LEFT(query, 80)                                             AS query_preview,
    calls,
    ROUND((total_exec_time / calls)::numeric, 2)               AS avg_ms,
    ROUND(total_exec_time::numeric, 2)                          AS total_ms,
    ROUND((rows / calls)::numeric, 1)                           AS avg_rows,
    ROUND(
        100.0 * total_exec_time / SUM(total_exec_time) OVER (), 2
    )                                                           AS pct_total_time
FROM pg_stat_statements
WHERE calls > 5
  AND query NOT LIKE '%pg_stat%'
ORDER BY avg_ms DESC
LIMIT 10;


-- ============================================================
-- 2. En Çok Çağrılan Sorgular (Yük Analizi)
-- ============================================================
SELECT
    LEFT(query, 80)                             AS query_preview,
    calls,
    ROUND(total_exec_time::numeric, 2)          AS total_ms,
    ROUND((total_exec_time / calls)::numeric, 2) AS avg_ms,
    ROUND(stddev_exec_time::numeric, 2)         AS stddev_ms
FROM pg_stat_statements
WHERE calls > 10
ORDER BY calls DESC
LIMIT 10;


-- ============================================================
-- 3. En Fazla I/O Yapan Sorgular (Buffer Hit vs Read)
-- ============================================================
SELECT
    LEFT(query, 80)                                         AS query_preview,
    calls,
    shared_blks_hit,
    shared_blks_read,
    CASE WHEN (shared_blks_hit + shared_blks_read) = 0 THEN 0
         ELSE ROUND(
             100.0 * shared_blks_hit /
             (shared_blks_hit + shared_blks_read), 1)
    END                                                     AS cache_hit_pct,
    shared_blks_dirtied,
    temp_blks_written
FROM pg_stat_statements
WHERE (shared_blks_hit + shared_blks_read) > 0
  AND calls > 5
ORDER BY shared_blks_read DESC
LIMIT 10;


-- ============================================================
-- 4. İstatistikleri Sıfırla (gerektiğinde)
-- ============================================================
-- SELECT pg_stat_statements_reset();
