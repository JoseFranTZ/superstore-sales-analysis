-- ============================================================
-- 06_by_segment.sql
-- Performance by customer segment and by ship mode.
-- ============================================================

-- Customer segment performance
SELECT
    Segment,
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct,
    COUNT(DISTINCT "Customer ID")               AS customers,
    COUNT(DISTINCT "Order ID")                 AS orders
FROM orders
GROUP BY Segment
ORDER BY sales DESC;


-- Ship mode performance
SELECT
    "Ship Mode",
    COUNT(*)                                    AS items,
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct
FROM orders
GROUP BY "Ship Mode"
ORDER BY margin_pct DESC;
