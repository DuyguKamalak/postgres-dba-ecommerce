#!/bin/bash
# ============================================================
# Backup & Restore — pg_dump / pg_restore
# ============================================================

CONTAINER="postgres_dba"
DB="ecommerce_db"
USER="dba_admin"
BACKUP_DIR="/data/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- BACKUP ---

# 1. Full database — custom format (en iyi sıkıştırma, pg_restore ile seçici restore)
docker exec $CONTAINER pg_dump \
    -U $USER \
    -d $DB \
    -F c \
    -Z 9 \
    -f $BACKUP_DIR/full_${TIMESTAMP}.dump

# 2. Schema-only backup
docker exec $CONTAINER pg_dump \
    -U $USER \
    -d $DB \
    --schema-only \
    -f $BACKUP_DIR/schema_${TIMESTAMP}.sql

# 3. Sadece ecommerce şeması
docker exec $CONTAINER pg_dump \
    -U $USER \
    -d $DB \
    -n ecommerce \
    -F c \
    -f $BACKUP_DIR/schema_ecommerce_${TIMESTAMP}.dump

# --- RESTORE ---

# Full restore (yeni veritabanına)
# docker exec $CONTAINER pg_restore \
#     -U $USER \
#     -d ecommerce_db_restore \
#     -F c \
#     $BACKUP_DIR/full_${TIMESTAMP}.dump

# Sadece tek tablo restore
# docker exec $CONTAINER pg_restore \
#     -U $USER \
#     -d $DB \
#     -t order_items \
#     $BACKUP_DIR/full_${TIMESTAMP}.dump

echo "Backup tamamlandi: $BACKUP_DIR/full_${TIMESTAMP}.dump"
