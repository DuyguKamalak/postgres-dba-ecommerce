-- Business Analytics — Window Functions
-- Veri seti: 99K sipariş, 1.5M+ satır
-- Teknikler: LAG/LEAD, SUM OVER, RANK, NTILE, cohort analizi, RFM skoru

SET search_path TO ecommerce;

-- ============================================================
-- 1. Aylık Satış Trendi + Önceki Aya Göre Büyüme (LAG)
-- ============================================================
WITH monthly_revenue AS (
    SELECT
        date_trunc('month', o.purchase_timestamp) AS month,
        COUNT(DISTINCT o.order_id)                AS order_count,
        SUM(oi.price + oi.freight_value)          AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.purchase_timestamp IS NOT NULL
    GROUP BY 1
)
SELECT
    month,
    order_count,
    ROUND(total_revenue, 2)                                                 AS total_revenue,
    LAG(order_count)  OVER (ORDER BY month)                                 AS prev_month_orders,
    ROUND(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month))
        / NULLIF(LAG(order_count) OVER (ORDER BY month), 0), 1
    )                                                                       AS order_growth_pct,
    ROUND(
        SUM(total_revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING), 2
    )                                                                       AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;


-- ============================================================
-- 2. Ürün Başına Kümülatif Gelir + Kategori Sıralaması
-- ============================================================
SELECT
    pc.category_name_english                                    AS category,
    p.product_id,
    ROUND(SUM(oi.price), 2)                                     AS product_revenue,
    ROUND(
        SUM(SUM(oi.price)) OVER (
            PARTITION BY p.category_name
            ORDER BY SUM(oi.price) DESC
            ROWS UNBOUNDED PRECEDING
        ), 2
    )                                                           AS cumulative_category_revenue,
    RANK() OVER (
        PARTITION BY p.category_name
        ORDER BY SUM(oi.price) DESC
    )                                                           AS rank_in_category,
    ROUND(
        100.0 * SUM(oi.price)
        / SUM(SUM(oi.price)) OVER (PARTITION BY p.category_name), 1
    )                                                           AS pct_of_category
FROM order_items oi
JOIN products p      ON oi.product_id = p.product_id
JOIN product_categories pc ON p.category_name = pc.category_name
GROUP BY pc.category_name_english, p.product_id, p.category_name
HAVING SUM(oi.price) > 0
ORDER BY category, rank_in_category
LIMIT 50;


-- ============================================================
-- 3. Müşteri Cohort Analizi
--    Müşteriler ilk alışveriş ayına göre gruplandırılır;
--    sonraki aylarda kaçı tekrar alışveriş yaptı gösterilir.
-- ============================================================
WITH first_purchase AS (
    SELECT
        c.customer_unique_id,
        date_trunc('month', MIN(o.purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        date_trunc('month', o.purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.purchase_timestamp IS NOT NULL
),
cohort_data AS (
    SELECT
        fp.cohort_month,
        co.order_month,
        COUNT(DISTINCT co.customer_unique_id) AS customers
    FROM customer_orders co
    JOIN first_purchase fp ON co.customer_unique_id = fp.customer_unique_id
    GROUP BY fp.cohort_month, co.order_month
)
SELECT
    cohort_month,
    order_month,
    customers,
    ROUND(
        100.0 * customers
        / FIRST_VALUE(customers) OVER (
            PARTITION BY cohort_month
            ORDER BY order_month
        ), 1
    ) AS retention_pct
FROM cohort_data
ORDER BY cohort_month, order_month
LIMIT 60;


-- ============================================================
-- 4. RFM Skoru — En Değerli Müşteriler
--    R (Recency): Son alışverişten bu yana geçen gün
--    F (Frequency): Toplam sipariş sayısı
--    M (Monetary): Toplam harcama
-- ============================================================
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.purchase_timestamp)                       AS last_purchase,
        COUNT(DISTINCT o.order_id)                      AS frequency,
        SUM(oi.price + oi.freight_value)                AS monetary
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.purchase_timestamp IS NOT NULL
      AND o.status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        last_purchase,
        frequency,
        ROUND(monetary, 2)                                           AS monetary,
        EXTRACT(DAY FROM (MAX(last_purchase) OVER () - last_purchase)) AS recency_days,
        NTILE(5) OVER (ORDER BY last_purchase DESC)                  AS r_score,
        NTILE(5) OVER (ORDER BY frequency)                           AS f_score,
        NTILE(5) OVER (ORDER BY monetary)                            AS m_score
    FROM rfm_base
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                   AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2                  THEN 'Lost'
        ELSE 'Potential Loyalist'
    END                                             AS customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC
LIMIT 30;


-- ============================================================
-- 5. Satıcı Performans Sıralaması (Running Total + Percentile)
-- ============================================================
WITH seller_stats AS (
    SELECT
        oi.seller_id,
        s.city                               AS seller_city,
        s.state                              AS seller_state,
        COUNT(DISTINCT oi.order_id)          AS total_orders,
        ROUND(SUM(oi.price), 2)              AS total_revenue,
        ROUND(AVG(oi.price), 2)              AS avg_order_value,
        AVG(r.review_score)                  AS avg_review_score
    FROM order_items oi
    JOIN sellers s      ON oi.seller_id = s.seller_id
    LEFT JOIN order_reviews r ON oi.order_id = r.order_id
    GROUP BY oi.seller_id, s.city, s.state
)
SELECT
    seller_id,
    seller_city,
    seller_state,
    total_orders,
    total_revenue,
    avg_order_value,
    ROUND(avg_review_score, 2)                                          AS avg_review_score,
    RANK()   OVER (ORDER BY total_revenue DESC)                         AS revenue_rank,
    PERCENT_RANK() OVER (ORDER BY total_revenue)                        AS revenue_percentile,
    ROUND(
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC
            ROWS UNBOUNDED PRECEDING), 2
    )                                                                   AS cumulative_revenue
FROM seller_stats
ORDER BY revenue_rank
LIMIT 20;
