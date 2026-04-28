-- ============================================================
-- 07_products.sql
-- Product-level winners and losers.
-- Also counts products with negative cumulative profit (discontinuation candidates).
-- ============================================================

-- Top 10 products by profit
SELECT
    "Product Name",
    Category,
    "Sub-Category",
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct,
    COUNT(*)                                    AS times_sold
FROM orders
GROUP BY "Product Name", Category, "Sub-Category"
ORDER BY profit DESC
LIMIT 10;


-- Top 10 products with highest cumulative losses
SELECT
    "Product Name",
    Category,
    "Sub-Category",
    ROUND(SUM(Sales), 0)                        AS sales,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct,
    COUNT(*)                                    AS times_sold
FROM orders
GROUP BY "Product Name", Category, "Sub-Category"
ORDER BY profit ASC
LIMIT 10;


-- Count of products with negative cumulative profit (candidates to discontinue)
SELECT COUNT(*) AS products_at_loss
FROM (
    SELECT "Product Name", SUM(Profit) AS total_profit
    FROM orders
    GROUP BY "Product Name"
    HAVING total_profit < 0
);
