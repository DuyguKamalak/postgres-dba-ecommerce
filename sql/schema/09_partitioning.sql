-- ============================================================
-- Tablo Partitioning — orders tablosunu yıla göre böl
-- Declarative Partitioning (PostgreSQL 10+, ek extension gerekmez)
-- ============================================================

-- 1. Yeni partition'lı ana tablo
CREATE TABLE ecommerce.orders_partitioned (
    order_id                    CHAR(32)      NOT NULL,
    customer_id                 CHAR(32)      NOT NULL,
    status                      VARCHAR(20)   NOT NULL,
    purchase_timestamp          TIMESTAMP,
    approved_at                 TIMESTAMP,
    delivered_carrier_date      TIMESTAMP,
    delivered_customer_date     TIMESTAMP,
    estimated_delivery_date     TIMESTAMP
) PARTITION BY RANGE (purchase_timestamp);

-- 2. Yıllık partition'lar
CREATE TABLE ecommerce.orders_2016
    PARTITION OF ecommerce.orders_partitioned
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE ecommerce.orders_2017
    PARTITION OF ecommerce.orders_partitioned
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE ecommerce.orders_2018
    PARTITION OF ecommerce.orders_partitioned
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE ecommerce.orders_2019
    PARTITION OF ecommerce.orders_partitioned
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

-- Tarih dışı / NULL olanlar için default partition
CREATE TABLE ecommerce.orders_default
    PARTITION OF ecommerce.orders_partitioned
    DEFAULT;

-- 3. Her partition'a index (ana tabloya konulan index otomatik kalıtılmaz)
CREATE INDEX idx_op_2016_ts ON ecommerce.orders_2016 (purchase_timestamp);
CREATE INDEX idx_op_2017_ts ON ecommerce.orders_2017 (purchase_timestamp);
CREATE INDEX idx_op_2018_ts ON ecommerce.orders_2018 (purchase_timestamp);
CREATE INDEX idx_op_2019_ts ON ecommerce.orders_2019 (purchase_timestamp);

-- 4. Mevcut veriyi kopyala
INSERT INTO ecommerce.orders_partitioned
SELECT * FROM ecommerce.orders;

-- 5. Sonuç: partition başına satır sayısı
SELECT
    child.relname AS partition,
    pg_size_pretty(pg_relation_size(child.oid)) AS size,
    (SELECT COUNT(*) FROM ecommerce.orders_partitioned
     WHERE purchase_timestamp >= split_part(child.relname,'_',2)::date
       AND purchase_timestamp < (split_part(child.relname,'_',2)::int + 1)::text::date
    ) AS approx_rows
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid  = child.oid
WHERE parent.relname = 'orders_partitioned'
ORDER BY child.relname;
