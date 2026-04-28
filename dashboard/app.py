"""
Superstore Sales Analysis — Phase 1 Dashboard
Runs from repo root: python dashboard/app.py
"""

import re
import sqlite3
from pathlib import Path

import dash
from dash import dcc, html
import plotly.graph_objects as go
import plotly.express as px
import pandas as pd

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
DB   = ROOT / "data" / "superstore.db"
SQL  = ROOT / "sql"

# ── Data loading ──────────────────────────────────────────────────────────────
def run_sql(file: str) -> list[pd.DataFrame]:
    """Read a .sql file, split on ';', return one DataFrame per statement."""
    text = (SQL / file).read_text()
    text = re.sub(r"--[^\n]*", "", text)          # strip line comments
    stmts = [s.strip() for s in text.split(";") if s.strip()]
    conn = sqlite3.connect(DB)
    results = [pd.read_sql_query(s, conn) for s in stmts]
    conn.close()
    return results


kpi         = run_sql("01_global_metrics.sql")[0]
cat, subcat = run_sql("02_by_category.sql")
discount    = run_sql("03_discount_impact.sql")[0]
region, states = run_sql("04_by_region.sql")
annual, monthly = run_sql("05_trends.sql")
segment, shipmode = run_sql("06_by_segment.sql")
prod_top, prod_bot, _ = run_sql("07_products.sql")
cust_top, cust_dist = run_sql("08_customers.sql")

# ── Colour palette ────────────────────────────────────────────────────────────
BLUE      = "#2563EB"
RED       = "#DC2626"
GREEN     = "#16A34A"
GREY      = "#6B7280"
LIGHT_BG  = "#F9FAFB"
CARD_BG   = "#FFFFFF"
TEXT_DARK = "#111827"
TEXT_MID  = "#374151"
BORDER    = "#E5E7EB"

# ── Shared style helpers ──────────────────────────────────────────────────────
CHART_LAYOUT = dict(
    paper_bgcolor=CARD_BG,
    plot_bgcolor=CARD_BG,
    font=dict(family="Inter, system-ui, sans-serif", color=TEXT_MID, size=12),
    margin=dict(l=16, r=16, t=40, b=16),
    legend=dict(bgcolor="rgba(0,0,0,0)", borderwidth=0),
)

def card(children, style=None):
    base = dict(
        background=CARD_BG,
        border=f"1px solid {BORDER}",
        borderRadius="10px",
        padding="20px",
        boxShadow="0 1px 3px rgba(0,0,0,.06)",
    )
    if style:
        base.update(style)
    return html.Div(children, style=base)

def section_title(text):
    return html.H2(text, style=dict(
        color=TEXT_DARK, fontSize="15px", fontWeight="600",
        letterSpacing=".04em", textTransform="uppercase",
        margin="0 0 16px 0", padding="0",
    ))

# ── KPI cards ─────────────────────────────────────────────────────────────────
def kpi_card(label, value, sub=None, color=TEXT_DARK):
    return card(html.Div([
        html.P(label, style=dict(color=GREY, fontSize="11px", fontWeight="600",
                                 letterSpacing=".08em", textTransform="uppercase",
                                 margin="0 0 6px 0")),
        html.P(value, style=dict(color=color, fontSize="26px", fontWeight="700",
                                 margin="0 0 2px 0", lineHeight="1")),
        html.P(sub or "", style=dict(color=GREY, fontSize="11px", margin="0")),
    ]), style=dict(flex="1", minWidth="140px"))

r = kpi.iloc[0]
kpi_row = html.Div([
    kpi_card("Total Sales",    f"${r.total_sales:,.0f}"),
    kpi_card("Total Profit",   f"${r.total_profit:,.0f}"),
    kpi_card("Profit Margin",  f"{r.margin_pct}%"),
    kpi_card("Total Orders",   f"{r.total_orders:,}",
             sub=f"{r.total_customers:,} customers"),
    kpi_card("Loss Rate",      f"{r.loss_rate_pct}%",
             sub=f"{r.loss_items:,} items at loss", color=RED),
    kpi_card("Discount Rate",  f"{r.discount_rate_pct}%",
             sub=f"{r.discounted_items:,} discounted items"),
], style=dict(display="flex", gap="12px", flexWrap="wrap"))

# ── Charts ────────────────────────────────────────────────────────────────────

# Category bar
fig_cat = go.Figure()
fig_cat.add_bar(x=cat["Category"], y=cat["sales"], name="Sales",
                marker_color=BLUE, yaxis="y")
fig_cat.add_scatter(x=cat["Category"], y=cat["margin_pct"], name="Margin %",
                    mode="lines+markers", marker=dict(size=8, color=GREEN),
                    line=dict(color=GREEN, width=2), yaxis="y2")
fig_cat.update_layout(**CHART_LAYOUT,
    title="Sales & Margin by Category",
    yaxis=dict(title="Sales ($)", gridcolor=BORDER),
    yaxis2=dict(title="Margin %", overlaying="y", side="right",
                showgrid=False, ticksuffix="%"),
)

# Sub-category horizontal bar
subcat_sorted = subcat.sort_values("profit")
colors_sub = [RED if v < 0 else BLUE for v in subcat_sorted["profit"]]
fig_subcat = go.Figure(go.Bar(
    y=subcat_sorted["Sub-Category"], x=subcat_sorted["profit"],
    orientation="h", marker_color=colors_sub,
    text=[f"${v:,.0f}" for v in subcat_sorted["profit"]],
    textposition="outside", textfont=dict(size=10),
))
fig_subcat.update_layout(**CHART_LAYOUT,
    title="Profit by Sub-Category",
    xaxis=dict(title="Profit ($)", showgrid=True, gridcolor=BORDER, zeroline=True,
               zerolinecolor=RED, zerolinewidth=1.5),
    yaxis=dict(showgrid=False),
    height=480,
)

# Annual trend
fig_annual = go.Figure()
fig_annual.add_bar(x=annual["year"], y=annual["sales"], name="Sales",
                   marker_color=BLUE)
fig_annual.add_scatter(x=annual["year"], y=annual["margin_pct"], name="Margin %",
                       mode="lines+markers", marker=dict(size=8, color=GREEN),
                       line=dict(color=GREEN, width=2), yaxis="y2")
fig_annual.update_layout(**CHART_LAYOUT,
    title="Annual Sales Trend (2014–2017)",
    yaxis=dict(title="Sales ($)", gridcolor=BORDER),
    yaxis2=dict(title="Margin %", overlaying="y", side="right",
                showgrid=False, ticksuffix="%"),
)

# Monthly seasonality
month_names = ["Jan","Feb","Mar","Apr","May","Jun",
               "Jul","Aug","Sep","Oct","Nov","Dec"]
monthly["month_name"] = monthly["month"].apply(lambda m: month_names[m-1])
fig_monthly = go.Figure(go.Bar(
    x=monthly["month_name"], y=monthly["sales"],
    marker_color=BLUE,
    text=[f"${v/1000:.0f}k" for v in monthly["sales"]],
    textposition="outside", textfont=dict(size=10),
))
fig_monthly.update_layout(**CHART_LAYOUT,
    title="Monthly Seasonality (all years)",
    yaxis=dict(title="Sales ($)", gridcolor=BORDER),
)

# Regional bars
fig_region = go.Figure()
fig_region.add_bar(x=region["Region"], y=region["sales"], name="Sales",
                   marker_color=BLUE)
fig_region.add_scatter(x=region["Region"], y=region["margin_pct"], name="Margin %",
                       mode="lines+markers", marker=dict(size=8, color=GREEN),
                       line=dict(color=GREEN, width=2), yaxis="y2")
fig_region.update_layout(**CHART_LAYOUT,
    title="Performance by Region",
    yaxis=dict(title="Sales ($)", gridcolor=BORDER),
    yaxis2=dict(title="Margin %", overlaying="y", side="right",
                showgrid=False, ticksuffix="%"),
)

# Bottom 10 states
fig_states = go.Figure(go.Bar(
    y=states["State"], x=states["profit"], orientation="h",
    marker_color=RED,
    text=[f"${v:,.0f}" for v in states["profit"]],
    textposition="outside", textfont=dict(size=10),
))
fig_states.update_layout(**CHART_LAYOUT,
    title="Bottom 10 States by Profit",
    xaxis=dict(title="Profit ($)", showgrid=True, gridcolor=BORDER),
    yaxis=dict(showgrid=False, autorange="reversed"),
)

# Discount impact
bucket_order = ["0%", "1-10%", "11-20%", "21-30%", "31-50%", ">50%"]
discount["discount_bucket"] = pd.Categorical(
    discount["discount_bucket"], categories=bucket_order, ordered=True)
discount = discount.sort_values("discount_bucket")

fig_discount = go.Figure()
fig_discount.add_bar(x=discount["discount_bucket"], y=discount["items"],
                     name="Items", marker_color=BLUE, yaxis="y")
fig_discount.add_scatter(x=discount["discount_bucket"], y=discount["margin_pct"],
                         name="Margin %", mode="lines+markers",
                         marker=dict(size=9, color=GREEN),
                         line=dict(color=GREEN, width=2), yaxis="y2")
fig_discount.add_hline(y=0, yref="y2", line_color=RED,
                       line_dash="dash", line_width=1.5)
fig_discount.update_layout(**CHART_LAYOUT,
    title="Discount Buckets vs Profit Margin",
    yaxis=dict(title="Items", gridcolor=BORDER),
    yaxis2=dict(title="Margin %", overlaying="y", side="right",
                showgrid=False, ticksuffix="%"),
)

# Segment
fig_segment = go.Figure()
fig_segment.add_bar(x=segment["Segment"], y=segment["sales"],
                    name="Sales", marker_color=BLUE)
fig_segment.add_scatter(x=segment["Segment"], y=segment["margin_pct"],
                        name="Margin %", mode="lines+markers",
                        marker=dict(size=8, color=GREEN),
                        line=dict(color=GREEN, width=2), yaxis="y2")
fig_segment.update_layout(**CHART_LAYOUT,
    title="Performance by Segment",
    yaxis=dict(title="Sales ($)", gridcolor=BORDER),
    yaxis2=dict(title="Margin %", overlaying="y", side="right",
                showgrid=False, ticksuffix="%"),
)

# Ship mode
fig_ship = go.Figure(go.Bar(
    x=shipmode["Ship Mode"], y=shipmode["margin_pct"],
    marker_color=BLUE,
    text=[f"{v}%" for v in shipmode["margin_pct"]],
    textposition="outside",
))
fig_ship.update_layout(**CHART_LAYOUT,
    title="Margin % by Ship Mode",
    yaxis=dict(title="Margin %", ticksuffix="%", gridcolor=BORDER),
)

# Products
prod_top5  = prod_top.head(10).sort_values("profit")
prod_bot5  = prod_bot.head(10).sort_values("profit", ascending=False)

# shorten long product names
def shorten(name, n=40):
    return name if len(name) <= n else name[:n] + "…"

fig_prod = go.Figure()
fig_prod.add_bar(
    y=[shorten(n) for n in prod_top5["Product Name"]],
    x=prod_top5["profit"],
    orientation="h", name="Top 10 Profitable",
    marker_color=GREEN,
)
fig_prod.add_bar(
    y=[shorten(n) for n in prod_bot5["Product Name"]],
    x=prod_bot5["profit"],
    orientation="h", name="Top 10 Losses",
    marker_color=RED,
)
fig_prod.update_layout(**CHART_LAYOUT,
    title="Top 10 Profitable vs Top 10 Loss-Making Products",
    xaxis=dict(title="Profit ($)", zeroline=True, zerolinecolor=GREY,
               gridcolor=BORDER),
    yaxis=dict(showgrid=False),
    height=520,
    barmode="overlay",
)

# Customers top 20
cust_top_s = cust_top.sort_values("sales")
cust_colors = [GREEN if p >= 0 else RED for p in cust_top_s["profit"]]
fig_cust = go.Figure(go.Bar(
    y=cust_top_s["Customer Name"], x=cust_top_s["sales"],
    orientation="h", marker_color=cust_colors,
    text=[f"${p:,.0f}" for p in cust_top_s["profit"]],
    textposition="outside", textfont=dict(size=10),
))
fig_cust.update_layout(**CHART_LAYOUT,
    title="Top 20 Customers by Sales  (bar color = profit sign)",
    xaxis=dict(title="Sales ($)", gridcolor=BORDER),
    yaxis=dict(showgrid=False),
    height=480,
)

# Customer profit distribution
dist_order = ["Heavy loss  (< -1000)", "Loss        (-1000 to 0)",
              "Low profit  (0 to 500)", "Mid profit  (500 to 2000)",
              "High profit (> 2000)"]
cust_dist["profit_bucket"] = pd.Categorical(
    cust_dist["profit_bucket"], categories=dist_order, ordered=True)
cust_dist = cust_dist.sort_values("profit_bucket")
dist_colors = [RED, "#F97316", GREY, "#60A5FA", GREEN]
fig_dist = go.Figure(go.Bar(
    x=cust_dist["profit_bucket"], y=cust_dist["customers"],
    marker_color=dist_colors,
    text=cust_dist["customers"], textposition="outside",
))
fig_dist.update_layout(**CHART_LAYOUT,
    title="Customer Profit Distribution",
    xaxis=dict(showgrid=False),
    yaxis=dict(title="Customers", gridcolor=BORDER),
)

# ── Layout ────────────────────────────────────────────────────────────────────
def row(*children, gap="16px"):
    return html.Div(list(children),
                    style=dict(display="flex", gap=gap, alignItems="stretch"))

def col(*children, flex="1"):
    return html.Div(list(children), style=dict(flex=flex, minWidth="0"))

app = dash.Dash(__name__, title="Superstore Analysis")

app.layout = html.Div(style=dict(
    background=LIGHT_BG, minHeight="100vh",
    fontFamily="Inter, system-ui, sans-serif",
    padding="0",
), children=[

    # ── Header ────────────────────────────────────────────────────────────────
    html.Div(style=dict(
        background=TEXT_DARK, padding="28px 40px", marginBottom="28px",
    ), children=[
        html.H1("Superstore Sales Analysis",
                style=dict(color="#FFFFFF", fontSize="22px", fontWeight="700",
                           margin="0 0 4px 0")),
        html.P("Phase 1 — Sales & Profitability  ·  2014–2017  ·  9,994 transactions",
               style=dict(color="#9CA3AF", fontSize="13px", margin="0")),
    ]),

    # ── Body ──────────────────────────────────────────────────────────────────
    html.Div(style=dict(padding="0 40px 40px 40px"), children=[

        # KPIs
        card([section_title("Overview"), kpi_row]),
        html.Div(style=dict(height="20px")),

        # Category & Sub-category
        card([
            section_title("Sales & Profitability by Category"),
            row(
                col(dcc.Graph(figure=fig_cat,    config={"displayModeBar": False})),
                col(dcc.Graph(figure=fig_subcat, config={"displayModeBar": False})),
            ),
        ]),
        html.Div(style=dict(height="20px")),

        # Trends
        card([
            section_title("Sales Trends"),
            row(
                col(dcc.Graph(figure=fig_annual,  config={"displayModeBar": False})),
                col(dcc.Graph(figure=fig_monthly, config={"displayModeBar": False})),
            ),
        ]),
        html.Div(style=dict(height="20px")),

        # Regional
        card([
            section_title("Regional Performance"),
            row(
                col(dcc.Graph(figure=fig_region, config={"displayModeBar": False})),
                col(dcc.Graph(figure=fig_states, config={"displayModeBar": False})),
            ),
        ]),
        html.Div(style=dict(height="20px")),

        # Discount
        card([
            section_title("Discount Impact"),
            dcc.Graph(figure=fig_discount, config={"displayModeBar": False}),
        ]),
        html.Div(style=dict(height="20px")),

        # Segment & Ship mode
        card([
            section_title("Customer Segments & Shipping"),
            row(
                col(dcc.Graph(figure=fig_segment, config={"displayModeBar": False})),
                col(dcc.Graph(figure=fig_ship,    config={"displayModeBar": False})),
            ),
        ]),
        html.Div(style=dict(height="20px")),

        # Products
        card([
            section_title("Product Analysis"),
            dcc.Graph(figure=fig_prod, config={"displayModeBar": False}),
        ]),
        html.Div(style=dict(height="20px")),

        # Customers
        card([
            section_title("Customer Analysis"),
            row(
                col(dcc.Graph(figure=fig_cust, config={"displayModeBar": False})),
                col(dcc.Graph(figure=fig_dist, config={"displayModeBar": False})),
            ),
        ]),

    ]),
])

if __name__ == "__main__":
    app.run(debug=False, port=8050)
