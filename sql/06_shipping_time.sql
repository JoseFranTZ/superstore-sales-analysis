-- ============================================================
-- 10_shipping_time.sql
-- Average shipping time in days by Ship Mode.
-- Dates are stored as ISO YYYY-MM-DD — julianday() is used for subtraction.
-- ============================================================

-- Ship time summary by Ship Mode
SELECT
    "Ship Mode",
    COUNT(*)                                                        AS orders,
    ROUND(MIN(julianday("Ship Date") - julianday("Order Date")), 0) AS min_days,
    ROUND(AVG(julianday("Ship Date") - julianday("Order Date")), 1) AS avg_days,
    ROUND(MAX(julianday("Ship Date") - julianday("Order Date")), 0) AS max_days
FROM orders
GROUP BY "Ship Mode"
ORDER BY avg_days;


-- Per-order ship days (used for boxplot)
SELECT
    "Ship Mode",
    CAST(julianday("Ship Date") - julianday("Order Date") AS INTEGER) AS ship_days
FROM orders
ORDER BY "Ship Mode";
