-- ============================================================
-- 03_discount_impact.sql
-- Impact of discount level on profit margin.
-- Buckets show the breakeven point and where discounts destroy value.
-- ============================================================

SELECT
    CASE
        WHEN Discount = 0        THEN '0%'
        WHEN Discount <= 0.10    THEN '1-10%'
        WHEN Discount <= 0.20    THEN '11-20%'
        WHEN Discount <= 0.30    THEN '21-30%'
        WHEN Discount <= 0.50    THEN '31-50%'
        ELSE                          '>50%'
    END                                                 AS discount_bucket,
    COUNT(*)                                            AS items,
    ROUND(AVG(Discount) * 100, 1)                      AS avg_discount_pct,
    ROUND(SUM(Sales), 0)                                AS sales,
    ROUND(SUM(Profit), 0)                               AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)           AS margin_pct
FROM orders
GROUP BY discount_bucket
ORDER BY
    CASE discount_bucket
        WHEN '0%'     THEN 1
        WHEN '1-10%'  THEN 2
        WHEN '11-20%' THEN 3
        WHEN '21-30%' THEN 4
        WHEN '31-50%' THEN 5
        ELSE               6
    END;
