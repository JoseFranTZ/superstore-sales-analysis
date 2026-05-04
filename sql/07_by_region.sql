-- ============================================================
-- 07_by_region.sql
-- Performance by Region and by State.
-- Surfaces the weakest regions and the states with highest losses,
-- including each loss-state's contribution to the total dataset-wide
-- loss pool (sum of negative profit across ALL line items).
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


-- State-level: bottom 10 by profit, with cumulative loss share of
-- the total dataset-wide loss pool (SUM of -Profit across every
-- line item with Profit < 0 in the entire orders table).
WITH state_profit AS (
    SELECT
        State,
        Region,
        SUM(Sales)  AS sales_raw,
        SUM(Profit) AS profit_raw
    FROM orders
    GROUP BY State, Region
),
loss_states AS (
    SELECT
        State, Region, sales_raw, profit_raw,
        -profit_raw AS loss_abs_raw
    FROM state_profit
    WHERE profit_raw < 0
),
total_dataset_loss AS (
    SELECT SUM(-Profit) AS total_loss_raw
    FROM orders
    WHERE Profit < 0
),
ranked AS (
    SELECT
        State, Region, sales_raw, profit_raw, loss_abs_raw,
        SUM(loss_abs_raw) OVER (
            ORDER BY loss_abs_raw DESC, State
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_loss_raw
    FROM loss_states
)
SELECT
    r.State,
    r.Region,
    ROUND(r.sales_raw, 0)                                  AS sales,
    ROUND(r.profit_raw, 0)                                 AS profit,
    ROUND(r.profit_raw / r.sales_raw * 100, 1)             AS margin_pct,
    ROUND(r.loss_abs_raw, 0)                               AS loss_abs,
    ROUND(r.cum_loss_raw, 0)                               AS cumulative_loss,
    ROUND(r.cum_loss_raw * 100.0 / t.total_loss_raw, 1)    AS cumulative_loss_pct_total
FROM ranked r
CROSS JOIN total_dataset_loss t
ORDER BY r.loss_abs_raw DESC
LIMIT 10;
