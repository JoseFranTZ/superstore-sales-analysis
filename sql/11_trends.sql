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


-- Quarterly trend by year: lets us compare each quarter across 2014–2017
-- instead of folding all years into a single Q1–Q4 aggregate.
SELECT
    strftime('%Y', "Order Date")                                            AS year,
    'Q' || ((CAST(strftime('%m', "Order Date") AS INTEGER) - 1) / 3 + 1)    AS quarter,
    COUNT(*)                                                                AS items,
    COUNT(DISTINCT "Order ID")                                              AS orders,
    ROUND(SUM(Sales), 0)                                                    AS sales,
    ROUND(SUM(Profit), 0)                                                   AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)                                AS margin_pct
FROM orders
GROUP BY year, quarter
ORDER BY year, quarter;


-- Monthly trend by year: lets us compare each month's margin across 2014–2017
-- instead of folding all years into a single Jan–Dec aggregate.
SELECT
    strftime('%Y', "Order Date")                    AS year,
    CAST(strftime('%m', "Order Date") AS INTEGER)   AS month,
    COUNT(*)                                         AS items,
    COUNT(DISTINCT "Order ID")                       AS orders,
    ROUND(SUM(Sales), 0)                             AS sales,
    ROUND(SUM(Profit), 0)                            AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)        AS margin_pct
FROM orders
GROUP BY year, month
ORDER BY year, month;
