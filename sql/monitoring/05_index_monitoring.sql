-- ============================================================
-- Index Monitoring — pg_stat_user_indexes
-- ============================================================

-- Index boyutları ve kullanım istatistikleri
SELECT
    indexrelname                                            AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid))           AS index_size,
    idx_scan                                               AS total_scans,
    idx_tup_read                                           AS tuples_read,
    idx_tup_fetch                                          AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'ecommerce'
ORDER BY idx_scan DESC;

-- Hiç kullanılmayan indexler (dead weight)
SELECT schemaname, relname AS table_name, indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS wasted_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname = 'ecommerce'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Tablo başına sequential scan vs index scan oranı
SELECT relname AS table_name,
       seq_scan,
       idx_scan,
       CASE WHEN (seq_scan + idx_scan) > 0
            THEN ROUND(100.0 * idx_scan / (seq_scan + idx_scan), 1)
            ELSE 0 END AS index_usage_pct,
       n_live_tup AS live_rows
FROM pg_stat_user_tables
WHERE schemaname = 'ecommerce'
ORDER BY seq_scan DESC;

-- Tablo ve index boyut karşılaştırması
SELECT
    t.relname                                                  AS table_name,
    pg_size_pretty(pg_relation_size(t.oid))                   AS table_size,
    pg_size_pretty(pg_indexes_size(t.oid))                    AS indexes_size,
    pg_size_pretty(pg_total_relation_size(t.oid))             AS total_size
FROM pg_class t
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'ecommerce'
  AND t.relkind = 'r'
ORDER BY pg_total_relation_size(t.oid) DESC;
