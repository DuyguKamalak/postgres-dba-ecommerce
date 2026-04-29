-- ============================================================
-- Rol ve Yetki Yönetimi
-- ============================================================

-- 1. readonly_user — sadece SELECT
CREATE ROLE readonly_user LOGIN PASSWORD 'readonly123';
GRANT CONNECT ON DATABASE ecommerce_db TO readonly_user;
GRANT USAGE ON SCHEMA ecommerce TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ecommerce
    GRANT SELECT ON TABLES TO readonly_user;

-- 2. analyst_user — SELECT + geçici tablo oluşturabilir
CREATE ROLE analyst_user LOGIN PASSWORD 'analyst123';
GRANT CONNECT ON DATABASE ecommerce_db TO analyst_user;
GRANT USAGE ON SCHEMA ecommerce TO analyst_user;
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO analyst_user;
GRANT TEMPORARY ON DATABASE ecommerce_db TO analyst_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ecommerce
    GRANT SELECT ON TABLES TO analyst_user;

-- 3. dba_admin zaten superuser — ek yetki gerekmez

-- Rolleri doğrula
SELECT rolname, rolsuper, rolinherit, rolcreaterole,
       rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname IN ('readonly_user', 'analyst_user', 'dba_admin')
ORDER BY rolname;
