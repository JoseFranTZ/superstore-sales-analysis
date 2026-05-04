-- ============================================================
-- 09_products.sql
-- Product-level winners and losers, with cumulative concentration
-- of profit / loss against the full product-level universe.
-- Also counts products with negative cumulative profit
-- (discontinuation candidates).
-- ============================================================

-- Top 10 products by profit, with cumulative share of total profit
-- across ALL profit-making products (not just the Top 10).
WITH product_profit AS (
    SELECT
        "Product Name",
        Category,
        "Sub-Category",
        SUM(Sales)  AS sales_raw,
        SUM(Profit) AS profit_raw,
        COUNT(*)    AS times_sold
    FROM orders
    GROUP BY "Product Name", Category, "Sub-Category"
),
profitable AS (
    SELECT *
    FROM product_profit
    WHERE profit_raw > 0
),
ranked AS (
    SELECT
        "Product Name", Category, "Sub-Category",
        sales_raw, profit_raw, times_sold,
        SUM(profit_raw) OVER (
            ORDER BY profit_raw DESC, "Product Name"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_profit_raw,
        SUM(profit_raw) OVER () AS total_profit_raw
    FROM profitable
)
SELECT
    "Product Name",
    Category,
    "Sub-Category",
    ROUND(sales_raw, 0)                                    AS sales,
    ROUND(profit_raw, 0)                                   AS profit,
    ROUND(profit_raw / sales_raw * 100, 1)                 AS margin_pct,
    times_sold,
    ROUND(cum_profit_raw, 0)                               AS cumulative_profit,
    ROUND(cum_profit_raw * 100.0 / total_profit_raw, 1)    AS cumulative_profit_pct_total
FROM ranked
ORDER BY profit_raw DESC
LIMIT 10;


-- Bottom 10 products by loss, with cumulative share of total loss
-- across ALL loss-making products (not just the Bottom 10).
WITH product_profit AS (
    SELECT
        "Product Name",
        Category,
        "Sub-Category",
        SUM(Sales)  AS sales_raw,
        SUM(Profit) AS profit_raw,
        COUNT(*)    AS times_sold
    FROM orders
    GROUP BY "Product Name", Category, "Sub-Category"
),
loss_products AS (
    SELECT *, -profit_raw AS loss_abs_raw
    FROM product_profit
    WHERE profit_raw < 0
),
ranked AS (
    SELECT
        "Product Name", Category, "Sub-Category",
        sales_raw, profit_raw, times_sold, loss_abs_raw,
        SUM(loss_abs_raw) OVER (
            ORDER BY loss_abs_raw DESC, "Product Name"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_loss_raw,
        SUM(loss_abs_raw) OVER () AS total_loss_raw
    FROM loss_products
)
SELECT
    "Product Name",
    Category,
    "Sub-Category",
    ROUND(sales_raw, 0)                                    AS sales,
    ROUND(profit_raw, 0)                                   AS profit,
    ROUND(profit_raw / sales_raw * 100, 1)                 AS margin_pct,
    times_sold,
    ROUND(loss_abs_raw, 0)                                 AS loss_abs,
    ROUND(cum_loss_raw, 0)                                 AS cumulative_loss,
    ROUND(cum_loss_raw * 100.0 / total_loss_raw, 1)        AS cumulative_loss_pct_total
FROM ranked
ORDER BY loss_abs_raw DESC
LIMIT 10;


-- Count of products with negative cumulative profit (candidates to discontinue)
SELECT COUNT(*) AS products_at_loss
FROM (
    SELECT "Product Name", SUM(Profit) AS total_profit
    FROM orders
    GROUP BY "Product Name"
    HAVING total_profit < 0
);
