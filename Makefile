COMPOSE = docker compose -f docker/docker-compose.yml
PSQL    = docker exec -i postgres_dba psql -U dba_admin -d ecommerce_db

.PHONY: up down restart status logs \
        import indexes roles partitioning \
        backup health

## Docker
up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

status:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f postgres

## Schema & Veri
import:
	docker cp sql/seed/02_import_data.sql postgres_dba:/tmp/import.sql
	docker exec postgres_dba psql -U dba_admin -d ecommerce_db -f /tmp/import.sql

indexes:
	$(PSQL) -f sql/indexes/04_create_indexes.sql

roles:
	$(PSQL) -f sql/schema/08_roles.sql

partitioning:
	$(PSQL) -f sql/schema/09_partitioning.sql

## Operasyon
backup:
	bash sql/backup/07_backup_restore.sh

health:
	bash scripts/health_check.sh
