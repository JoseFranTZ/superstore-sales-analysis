-- ============================================================
-- 01_global_metrics.sql
-- Global KPIs: total sales, profit, margin, customers, orders,
-- loss rate, and discount rate across the full dataset.
-- ============================================================

SELECT
    COUNT(*)                                                                        AS total_line_items,
    ROUND(SUM(Sales), 0)                                                            AS total_sales,
    ROUND(SUM(Profit), 0)                                                           AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)                                       AS margin_pct,
    COUNT(DISTINCT "Customer ID")                                                   AS total_customers,
    COUNT(DISTINCT "Order ID")                                                      AS total_orders,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END)                                   AS loss_items,
    ROUND(SUM(CASE WHEN Profit < 0 THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)     AS loss_rate_pct,
    SUM(CASE WHEN Discount > 0 THEN 1 ELSE 0 END)                                 AS discounted_items,
    ROUND(SUM(CASE WHEN Discount > 0 THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS discount_rate_pct
FROM orders;
