-- ============================================================
-- 05_trends.sql
-- Annual growth trend and monthly seasonality.
-- Dates are stored as ISO YYYY-MM-DD — strftime() is used for extraction.
-- ============================================================

-- Annual trend: 2014–2017
SELECT
    strftime('%Y', "Order Date")               AS year,
    COUNT(*)                                   AS items,
    COUNT(DISTINCT "Order ID")                 AS orders,
    ROUND(SUM(Sales), 0)                       AS sales,
    ROUND(SUM(Profit), 0)                      AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)  AS margin_pct
FROM orders
GROUP BY year
ORDER BY year;


-- Monthly seasonality (all years combined)
SELECT
    CAST(strftime('%m', "Order Date") AS INTEGER)  AS month,
    COUNT(*)                                        AS items,
    ROUND(SUM(Sales), 0)                            AS sales,
    ROUND(SUM(Profit), 0)                           AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)       AS margin_pct
FROM orders
GROUP BY month
ORDER BY month;
