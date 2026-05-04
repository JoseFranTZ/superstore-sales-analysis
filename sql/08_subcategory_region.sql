-- ============================================================
-- 11_subcategory_region.sql
-- Profit margin % by Sub-Category and Region (cross-tab).
-- Purpose: test whether Furniture losses are structural or
-- concentrated in specific regions.
-- ============================================================

SELECT
    "Sub-Category",
    Region,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 1)  AS margin_pct
FROM orders
GROUP BY "Sub-Category", Region
ORDER BY "Sub-Category", Region;
