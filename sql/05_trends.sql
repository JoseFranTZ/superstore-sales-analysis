-- ============================================================
-- 05_trends.sql
-- Annual growth trend and monthly seasonality.
-- Date format in dataset is M/D/YYYY — extracted with substr().
-- ============================================================

-- Annual trend: 2014–2017
SELECT
    substr("Order Date", -4)                    AS year,
    COUNT(*)                                    AS items,
    COUNT(DISTINCT "Order ID")                 AS orders,
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct
FROM orders
GROUP BY year
ORDER BY year;


-- Monthly seasonality (all years combined)
-- Month extracted as integer from the leading digits before the first '/'
SELECT
    CAST(substr("Order Date", 1, instr("Order Date", '/') - 1) AS INTEGER)  AS month,
    COUNT(*)                                                                  AS items,
    ROUND(SUM(Sales), 0)                                                      AS sales,
    ROUND(SUM(Profit), 0)                                                     AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)                                 AS margin_pct
FROM orders
GROUP BY month
ORDER BY month;
