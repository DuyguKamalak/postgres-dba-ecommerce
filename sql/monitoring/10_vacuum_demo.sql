-- ============================================================
-- VACUUM ANALYZE Demo — Dead Row Bloat & Temizlik
-- ============================================================

-- 1. Mevcut tablo sağlığını kontrol et
SELECT relname AS table_name,
       n_live_tup, n_dead_tup,
       ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
       pg_size_pretty(pg_relation_size(schemaname||'.'||relname)) AS size,
       last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'ecommerce'
ORDER BY n_dead_tup DESC;

-- 2. Yapay bloat oluştur (demo)
-- ALTER TABLE ecommerce.orders SET (autovacuum_enabled = false);
-- UPDATE ecommerce.orders SET status = status;  -- tüm satırları günceller = dead rows

-- 3. VACUUM (sadece dead rows temizler, alan OS'a iade edilmez)
VACUUM (VERBOSE, ANALYZE) ecommerce.orders;

-- 4. VACUUM FULL (tablo kilidler, alan OS'a iade edilir — production'da dikkatli)
-- VACUUM FULL ecommerce.orders;

-- 5. REINDEX (şişmiş index'leri yeniden oluştur)
-- REINDEX TABLE ecommerce.orders;

-- 6. Sonuç kontrol
SELECT relname,
       n_live_tup, n_dead_tup,
       pg_size_pretty(pg_relation_size(schemaname||'.'||relname)) AS size_after
FROM pg_stat_user_tables
WHERE schemaname = 'ecommerce' AND relname = 'orders';

-- NOT: VACUUM alan işaretler (reusable), OS'a iade etmez.
--      VACUUM FULL fiziksel küçültür ama ACCESS EXCLUSIVE LOCK alır.
--      Production'da pg_repack extension tercih edilir (kilit almadan).
