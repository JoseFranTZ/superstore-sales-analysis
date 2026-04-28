-- ============================================================
-- 02_by_category.sql
-- Performance breakdown by Category and Sub-Category.
-- Identifies top performers and loss-generating sub-categories.
-- ============================================================

-- Category-level: sales share, profit share, margin
SELECT
    Category,
    ROUND(SUM(Sales), 0)                                                        AS sales,
    ROUND(SUM(Sales) / (SELECT SUM(Sales) FROM orders) * 100, 1)               AS sales_pct,
    ROUND(SUM(Profit), 0)                                                       AS profit,
    ROUND(SUM(Profit) / (SELECT SUM(Profit) FROM orders) * 100, 1)             AS profit_pct,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)                                   AS margin_pct
FROM orders
GROUP BY Category
ORDER BY sales DESC;


-- Sub-category level: ranked by profit (shows top performers and loss-makers)
SELECT
    "Sub-Category",
    Category,
    ROUND(SUM(Sales), 0)                        AS sales,
    COUNT(*)                                    AS items_sold,
    ROUND(SUM(Profit), 0)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)   AS margin_pct
FROM orders
GROUP BY "Sub-Category", Category
ORDER BY profit DESC;
