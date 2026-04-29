-- ============================================================
-- Data Import: CSV -> ecommerce schema
-- Run from inside the container where /data/raw is mounted
-- ============================================================

-- 1. Product categories (translation file - no nulls expected)
COPY ecommerce.product_categories(category_name, category_name_english)
FROM '/data/raw/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 2. Customers
COPY ecommerce.customers(customer_id, customer_unique_id, zip_code_prefix, city, state)
FROM '/data/raw/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 3. Sellers
COPY ecommerce.sellers(seller_id, zip_code_prefix, city, state)
FROM '/data/raw/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 4. Products (some category_name values may not exist in translation table -> NULL them)
COPY ecommerce.products(product_id, category_name, name_length, description_length,
                         photos_qty, weight_g, length_cm, height_cm, width_cm)
FROM '/data/raw/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

-- 5. Orders
COPY ecommerce.orders(order_id, customer_id, status, purchase_timestamp, approved_at,
                       delivered_carrier_date, delivered_customer_date, estimated_delivery_date)
FROM '/data/raw/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

-- 6. Order items
COPY ecommerce.order_items(order_id, order_item_id, product_id, seller_id,
                            shipping_limit_date, price, freight_value)
FROM '/data/raw/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

-- 7. Order payments
COPY ecommerce.order_payments(order_id, payment_sequential, payment_type,
                               payment_installments, payment_value)
FROM '/data/raw/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

-- 8. Order reviews
COPY ecommerce.order_reviews(review_id, order_id, score, comment_title, comment_message,
                              creation_date, answer_timestamp)
FROM '/data/raw/olist_order_reviews_dataset.csv'
WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

-- 9. Geolocation
COPY ecommerce.geolocation(zip_code_prefix, latitude, longitude, city, state)
FROM '/data/raw/olist_geolocation_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
