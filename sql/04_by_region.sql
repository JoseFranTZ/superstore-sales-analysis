-- ============================================================
-- 04_by_region.sql
-- Performance by Region and by State.
-- Surfaces the weakest regions and the states with highest losses.
-- ============================================================

-- Region-level performance
SELECT
    Region,
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct,
    COUNT(DISTINCT "Order ID")                 AS orders,
    COUNT(DISTINCT "Customer ID")               AS customers
FROM orders
GROUP BY Region
ORDER BY profit DESC;


-- State-level: bottom 10 by profit (loss detection)
SELECT
    State,
    Region,
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct
FROM orders
GROUP BY State, Region
ORDER BY profit ASC
LIMIT 10;
