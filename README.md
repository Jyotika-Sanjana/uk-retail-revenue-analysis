# uk-retail-revenue-analysis

# UK Online Retail — SQL Revenue & Returns Analysis

## Overview
Analysis of a real e-commerce transaction dataset (UCI Online Retail, 
~540K rows) using PostgreSQL to  analyse: top-selling products, data 
quality issues, and returns impact on revenue.
- Data-handling note :
  Product revenue excludes non-product entries such as postage, discounts and adjustments, identified by stock-code pattern.   The raw data is kept unchanged, and all queries use one filter so results stay consistent

## Dataset
UK-based online retailer, Dec 2010–Dec 2011. Each row is a line item 
in a customer order (invoice number, product, quantity, price, 
customer, country).
https://archive.ics.uci.edu/dataset/352/online-retail

## Analysis

**1. Which products generate the most revenue?**
Initial ranking was misleading — shipping charges ("POSTAGE", 
"DOTCOM POSTAGE") and internal adjustment codes ("MANUAL", 
"DISCOUNT", "BANK CHARGES") were mixed in with real products. 
Filtered these using stock code patterns (real product codes always 
contain a digit; junk codes don't), rather than a hardcoded list, 
so the filter generalizes to new junk codes too.

**2. How much revenue is lost to returns, and which products are 
most affected?**
- Finding: The product with the largest apparent "return loss" 
  (PAPER CRAFT, LITTLE BIRDIE, -£168K) turned out to be a single 
  wholesale order of 80,995 units cancelled 12 minutes after purchase 
  not a genuine customer-return pattern. Traced the cancellation 
  back to its matching original order to confirm, then excluded 
  extreme-quantity returns to get a cleaner view of real returns 
  behavior.
- Recommendation:
    1. Report bulk orders (above a quantity threshold) separately from regular orders, so one large order cannot dominate a returns report.
    2. Flag cancellations that closely match an original order within a short window as likely order errors, not customer returns, and exclude them from return-rate analysis. A shipped/not-shipped field would let the business confirm this.
    3. Evaluate product returns by return rate (returned value ÷ sold value), not by total returned value, so popular products are not mistaken for problem products.
    4. Prevention idea (to test): an order review step with a high-quantity warning
Limitation: the dataset has no shipping status or return reasons, so cancelled-before-dispatch is inferred from timing and matching quantities, not confirmed.

**3**.Checked Revenue by country

**4**.**Revenue trend over time (by month)**:
Net product revenue: after returns and cancellations, excluding non-product entries such as postage and adjustments.

- Finding: Monthly revenue moved in a moderate range from December 2010 to August 2011, then rose sharply from September to    November 2011, peaking in November. December 2011 appears to drop, but the data ends on 9 December. Revenue per day with     sales in December 2011 is almost the same as November’s, so the drop is largely explained by missing days, not weaker
  sales.
- Recommendation: Plan stock, staffing and delivery capacity ahead of September to November, the strongest period in this      dataset. Report December by revenue per day, not by monthly total, until a full month of data is available. With one year    of data, confirm the seasonal pattern against a second year.

**5**. **Also found**: Verified that September–November 2011 are complete months (consistent day coverage), confirming the revenue growth across this period is genuine — not an artifact of partial-month data, unlike December.

**6. Was November's revenue spike driven by a few large orders or 
broad growth?**
The two largest individual orders in November (£52,940 and £50,653) 
stood out from the rest, but together they represented only ~7.2% 
of the month's total revenue (£103,594 of £1,433,882) — confirming 
the growth was broad-based, not concentrated in a handful of 
transactions. This contrasts with the returns outlier above, where 
a single order accounted for effectively 100% of the anomaly.

**7. Which customers are the most valuable?**
Ranked customers by total spend, excluding ~20% of revenue tied to 
transactions with no CustomerID recorded (a data quality gap worth 
flagging on its own). Verified the top two customers' totals came 
from genuine repeat purchasing (74 and 60 separate orders 
respectively), not a single bulk transaction.

**8.:Calculated the Average Order Value** :
Calculating average order value (total spend ÷ number of distinct 
orders, not a plain AVG() on revenue — which would average per 
product line instead of per order) revealed customers aren't 
valuable in the same way: some (e.g., Customer 12415, 24 orders, 
£5,151 avg) are infrequent high-ticket buyers, while others 
(e.g., Customer 14911, 243 orders, £547 avg) drive value through 
purchase frequency. This distinction matters for how a business 
would target retention vs. acquisition for each group.
Recommendation:
- Treat the two groups differently. Frequent buyers are best served with retention efforts such as reorder reminders or loyalty offers. High-value occasional buyers may be wholesale-type customers, so they may respond better to account management, bulk pricing or restock reminders. Check this before acting.
- Investigate why about a fifth of revenue has no customer ID (guest checkout or recording errors) and report customer metrics with that gap stated. If it’s guest checkout, consider an optional account step instead of a mandatory one, to avoid losing sales.
- Limitation: results describe the top customers by spend and exclude revenue with no customer ID, so they do not represent the whole customer base
## Tools
PostgreSQL, pgAdmin

## Files
- `da_practice.sql` — all queries, in order, with comments
