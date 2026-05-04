-- ============================================================
-- 10_customers.sql
-- Customer-level profitability analysis.
-- Surfaces high-volume but unprofitable customers, top/bottom by
-- profit (with cumulative concentration vs the full customer
-- universe), profit-bucket distribution, Pareto curve, and
-- years-active retention recurrence.
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


-- Top 20 customers by total profit, with cumulative share of total
-- profit across ALL profit-making customers (not just the Top 20).
WITH customer_profit AS (
    SELECT
        "Customer Name",
        Segment,
        Region,
        COUNT(DISTINCT "Order ID") AS orders,
        SUM(Sales)                 AS sales_raw,
        SUM(Profit)                AS profit_raw
    FROM orders
    GROUP BY "Customer Name", Segment, Region
),
profitable AS (
    SELECT *
    FROM customer_profit
    WHERE profit_raw > 0
),
ranked AS (
    SELECT
        "Customer Name", Segment, Region, orders,
        sales_raw, profit_raw,
        SUM(profit_raw) OVER (
            ORDER BY profit_raw DESC, "Customer Name"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_profit_raw,
        SUM(profit_raw) OVER () AS total_profit_raw
    FROM profitable
)
SELECT
    "Customer Name",
    Segment,
    Region,
    orders,
    ROUND(sales_raw, 0)                                    AS sales,
    ROUND(profit_raw, 0)                                   AS profit,
    ROUND(profit_raw / sales_raw * 100, 1)                 AS margin_pct,
    ROUND(cum_profit_raw, 0)                               AS cumulative_profit,
    ROUND(cum_profit_raw * 100.0 / total_profit_raw, 1)    AS cumulative_profit_pct_total
FROM ranked
ORDER BY profit_raw DESC
LIMIT 20;


-- Bottom 20 customers by loss, with cumulative share of total loss
-- across ALL loss-making customers (not just the Bottom 20).
WITH customer_profit AS (
    SELECT
        "Customer Name",
        Segment,
        Region,
        COUNT(DISTINCT "Order ID") AS orders,
        SUM(Sales)                 AS sales_raw,
        SUM(Profit)                AS profit_raw
    FROM orders
    GROUP BY "Customer Name", Segment, Region
),
loss_customers AS (
    SELECT *, -profit_raw AS loss_abs_raw
    FROM customer_profit
    WHERE profit_raw < 0
),
ranked AS (
    SELECT
        "Customer Name", Segment, Region, orders,
        sales_raw, profit_raw, loss_abs_raw,
        SUM(loss_abs_raw) OVER (
            ORDER BY loss_abs_raw DESC, "Customer Name"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_loss_raw,
        SUM(loss_abs_raw) OVER () AS total_loss_raw
    FROM loss_customers
)
SELECT
    "Customer Name",
    Segment,
    Region,
    orders,
    ROUND(sales_raw, 0)                                    AS sales,
    ROUND(profit_raw, 0)                                   AS profit,
    ROUND(profit_raw / sales_raw * 100, 1)                 AS margin_pct,
    ROUND(loss_abs_raw, 0)                                 AS loss_abs,
    ROUND(cum_loss_raw, 0)                                 AS cumulative_loss,
    ROUND(cum_loss_raw * 100.0 / total_loss_raw, 1)        AS cumulative_loss_pct_total
FROM ranked
ORDER BY loss_abs_raw DESC
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


-- All customers ranked by profit (for Pareto / concentration curve)
SELECT
    "Customer Name",
    ROUND(SUM(Profit), 0)  AS profit
FROM orders
GROUP BY "Customer Name"
ORDER BY profit DESC;


-- Customer retention recurrence (years-active dimension): cohort each customer by
-- the number of distinct calendar years they ordered in (1, 2, 3, or 4), then aggregate.
-- Distinct from order-frequency recurrence (4.4.2 / 4.4.3 use avg orders/customer);
-- this view captures whether customers come back across multiple years.
SELECT
    years_active,
    COUNT(*)                                            AS customers,
    ROUND(SUM(profit), 0)                               AS total_profit,
    ROUND(SUM(sales), 0)                                AS total_sales,
    ROUND(SUM(profit) / SUM(sales) * 100, 1)            AS margin_pct,
    ROUND(AVG(profit), 0)                               AS avg_profit_per_customer,
    ROUND(AVG(orders), 1)                               AS avg_orders_per_customer
FROM (
    SELECT
        "Customer ID",
        COUNT(DISTINCT strftime('%Y', "Order Date"))    AS years_active,
        COUNT(DISTINCT "Order ID")                      AS orders,
        SUM(Sales)                                      AS sales,
        SUM(Profit)                                     AS profit
    FROM orders
    GROUP BY "Customer ID"
) AS per_customer
GROUP BY years_active
ORDER BY years_active;
