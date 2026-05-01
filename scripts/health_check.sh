#!/usr/bin/env bash
# PostgreSQL Günlük Sağlık Kontrol Scripti
# Kullanım: bash scripts/health_check.sh

set -euo pipefail

DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-ecommerce_db}"
DB_USER="${POSTGRES_USER:-dba_admin}"
PGPASSWORD="${POSTGRES_PASSWORD:-dba_password123}"
CONTAINER="postgres_dba"

export PGPASSWORD

WARN=0
LOG_FILE="scripts/health_check_$(date +%Y%m%d).log"

log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
warn() { log "WARNING: $*"; WARN=$((WARN + 1)); }
ok()   { log "OK      : $*"; }

psql_exec() {
    docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
        -t -A -c "$1" 2>/dev/null
}

log "===== PostgreSQL Sağlık Kontrolü — $(date '+%Y-%m-%d') ====="

# 1. Bağlantı testi
if psql_exec "SELECT 1" > /dev/null; then
    ok "Veritabanı bağlantısı başarılı"
else
    warn "Veritabanına bağlanılamadı!"
    exit 1
fi

# 2. Cache hit oranı (eşik: %95)
CACHE_HIT=$(psql_exec "
    SELECT ROUND(
        100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2
    ) FROM pg_stat_database WHERE datname = '$DB_NAME';")
if awk "BEGIN{exit !($CACHE_HIT < 95)}"; then
    warn "Cache hit düşük: %${CACHE_HIT} (eşik: %95)"
else
    ok "Cache hit: %${CACHE_HIT}"
fi

# 3. Dead row oranı (eşik: %10)
DEAD_ROWS=$(psql_exec "
    SELECT COALESCE(
        ROUND(100.0 * SUM(n_dead_tup) / NULLIF(SUM(n_live_tup + n_dead_tup), 0), 2),
        0)
    FROM pg_stat_user_tables;")
if awk "BEGIN{exit !($DEAD_ROWS > 10)}"; then
    warn "Dead row oranı yüksek: %${DEAD_ROWS} — VACUUM ANALYZE çalıştır"
else
    ok "Dead row oranı: %${DEAD_ROWS}"
fi

# 4. Kullanılmayan indexler
UNUSED=$(psql_exec "
    SELECT COUNT(*) FROM pg_stat_user_indexes
    WHERE idx_scan = 0
      AND indexrelname NOT LIKE '%pkey%'
      AND indexrelname NOT LIKE '%unique%';")
if [ "$UNUSED" -gt 0 ]; then
    warn "${UNUSED} adet kullanılmayan index var (pg_stat_user_indexes'e bak)"
else
    ok "Kullanılmayan index yok"
fi

# 5. Uzun süren sorgular (eşik: 5 dakika)
LONG_QUERIES=$(psql_exec "
    SELECT COUNT(*) FROM pg_stat_activity
    WHERE state = 'active'
      AND query_start < NOW() - INTERVAL '5 minutes'
      AND query NOT LIKE '%pg_stat_activity%';")
if [ "$LONG_QUERIES" -gt 0 ]; then
    warn "${LONG_QUERIES} adet 5 dakikadan uzun süren sorgu var"
else
    ok "Uzun süren sorgu yok"
fi

# 6. Bağlantı kullanımı (eşik: %80)
CONN_USAGE=$(psql_exec "
    SELECT ROUND(
        100.0 * COUNT(*) / current_setting('max_connections')::int, 1
    ) FROM pg_stat_activity;")
if awk "BEGIN{exit !($CONN_USAGE > 80)}"; then
    warn "Bağlantı kullanımı yüksek: %${CONN_USAGE}"
else
    ok "Bağlantı kullanımı: %${CONN_USAGE}"
fi

# 7. Veritabanı boyutu
DB_SIZE=$(psql_exec "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));")
ok "Veritabanı boyutu: $DB_SIZE"

log "===== Kontrol tamamlandı — ${WARN} uyarı ====="
[ "$WARN" -gt 0 ] && exit 1 || exit 0
