-- ============================================================
-- 08_customers.sql
-- Customer-level profitability analysis.
-- Surfaces high-volume but unprofitable customers and profit distribution.
-- ============================================================

-- Top 20 customers by total sales (with profit and margin)
SELECT
    "Customer Name",
    Segment,
    Region,
    COUNT(DISTINCT "Order ID")                 AS orders,
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct
FROM orders
GROUP BY "Customer Name", Segment, Region
ORDER BY sales DESC
LIMIT 20;


-- Customer profit distribution (how many customers are profitable vs destructive)
SELECT
    CASE
        WHEN total_profit < -1000 THEN 'Heavy loss  (< -1000)'
        WHEN total_profit <     0 THEN 'Loss        (-1000 to 0)'
        WHEN total_profit <   500 THEN 'Low profit  (0 to 500)'
        WHEN total_profit <  2000 THEN 'Mid profit  (500 to 2000)'
        ELSE                           'High profit (> 2000)'
    END             AS profit_bucket,
    COUNT(*)        AS customers
FROM (
    SELECT "Customer Name", SUM(Profit) AS total_profit
    FROM orders
    GROUP BY "Customer Name"
)
GROUP BY profit_bucket
ORDER BY MIN(total_profit);
