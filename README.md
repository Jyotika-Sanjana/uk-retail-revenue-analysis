# UK Online Retail — SQL Revenue & Returns Analysis

## Overview
Analysis of a real e-commerce transaction dataset (UCI Online Retail, ~540K rows) using PostgreSQL to examine top-selling products, data quality issues, returns, monthly revenue trends and customer value.

**Data-handling note:** Product revenue excludes non-product entries such as postage, discounts and adjustments, identified by stock-code pattern. The raw data is kept unchanged, and queries apply the same stock-code filter; the first query runs without it, to show the misleading ranking.

## Key Findings
- The largest apparent return loss (-£168K) was a single 80,995-unit order cancelled 12 minutes after purchase, not a customer-return pattern.
- Ranking products by return rate can also mislead: for two of the highest-ranked products, reversals of earlier full orders produced most of the "returns".
- Monthly revenue rose sharply from September to November 2011. The December drop reflects missing days (the data ends on 9 December), and revenue per day with sales is almost the same as November's.
- November's spike was broad-based: the two largest orders made up only ~7.2% of the month's revenue.
- Top customers split into frequent low-basket buyers and infrequent high-basket buyers, and about 20% of revenue has no customer ID.

## Dataset
UK-based online retailer, Dec 2010–Dec 2011. Each row is a line item in a customer order (invoice number, product, quantity, price, customer, country).

Source: [UCI Online Retail](https://archive.ics.uci.edu/dataset/352/online-retail)

**Setup:** the data is loaded into PostgreSQL as `retail_project."OnlineRetailCSV"`. `InvoiceDate` is stored as text in `MM/DD/YYYY HH24:MI` format, so queries convert it with `TO_DATE`.

## Analysis

### 1. Which products generate the most revenue?
**Finding:** The initial ranking was misleading. Shipping charges ("POSTAGE", "DOTCOM POSTAGE") and internal adjustment codes ("MANUAL", "DISCOUNT", "BANK CHARGES") were mixed in with real products. I filtered these using stock-code patterns (in this dataset, real product codes contain a digit) rather than a hardcoded list, so the filter may also catch similar codes.

### 2. How much revenue is lost to returns, and which products are most affected?
**Finding:** The product with the largest apparent "return loss" (PAPER CRAFT, LITTLE BIRDIE, -£168K) turned out to be a single order of 80,995 units cancelled 12 minutes after purchase, not a genuine customer-return pattern. I traced the cancellation back to its matching original order to confirm, then excluded extreme-quantity returns to get a cleaner view of real return behavior.

**Recommendation:**
1. Report bulk orders (above a quantity threshold) separately from regular orders, so one large order cannot dominate a returns report.
2. Flag returns that reverse an earlier full order (same product, quantity and price) and report them separately from customer returns, so they do not distort return-rate analysis. A shipped/not-shipped field and a return reason would let the business tell cancellations from genuine returns.
3. Evaluate product returns by return rate (returned value ÷ sold value), not by total returned value, so popular products are not mistaken for problem products (see section 3).
4. Prevention idea (to test): an order review step with a high-quantity warning.

**Limitation:** The dataset has no shipping status or return reasons, so cancelled-before-dispatch is inferred from timing and matching quantities, not confirmed. A single quantity cutoff (1,000 units) caught this outlier but missed smaller reversals of full orders, such as 756 and 240 units, so matching returns to their original sales is more reliable than a cutoff.

**Method note: order-size cutoffs.** Sale quantities have a median of 3, a 90th percentile of 24, a 99th percentile of 100 and a maximum of 80,995. Of the 6,769 rows with 100 or more units, 6,640 fall between 100 and 999, 126 between 1,000 and 9,999, and 3 at 10,000 or more. A cutoff of 100 would therefore discard many ordinary large orders, so I used percentiles to label Small, Medium and Bulk orders and checked where the extreme quantities sit.

### 3. Which products have the highest return rate?
**Finding:** Ranking by returned value favors popular products, so I ranked by return rate (returned value ÷ sold value), excluding quantities beyond ±999 and products with sales of £1,000 or less. The top of the list was misleading in two cases.
- The pantry chopping board ranked second at about 82%, but about 99.6% of its returned value came from two returns (756 and 186 units) that each reversed an earlier full order, 22 hours and 9 days later. Its other returns were single units.
- For the Babushka stacking tins (92%), a 240-unit credit note and sale entered one minute apart inflated the rate. Without that pair it fell to about 40% on only £70 of returns.

**Recommendation:**
1. Judge product returns by number of return orders and typical return size, as well as value.
2. Match large returns to earlier sales of the same product, quantity and price, and report them as full-order reversals.
3. Capture a return reason and shipping status.

**Limitation:** The dataset has no return reasons, so reversals could be returns, credits or cancellations. The 756-unit and 240-unit reversals fall below the 1,000-unit cutoff, so one quantity cutoff is not a reliable fix.

### 4. How does revenue change over time (by month)?
*Net product revenue: after returns and cancellations, excluding non-product entries such as postage and adjustments.*

**Finding:** Monthly revenue moved in a moderate range from December 2010 to August 2011, then rose sharply from September to November 2011, peaking in November. December 2011 appears to drop, but the data ends on 9 December. Revenue per day with sales in December 2011 is almost the same as November's, so the drop is largely explained by missing days, not weaker sales.

**Also checked:** September–November 2011 are complete months (consistent day coverage), so the growth across this period is consistent with genuine growth and not an artifact of partial-month data, unlike December.

**Recommendation:** Plan stock, staffing and delivery capacity ahead of September to November, the strongest period in this dataset. Report December by revenue per day, not by monthly total, until a full month of data is available. With one year of data, confirm the seasonal pattern against a second year.

### 5. Was November's revenue spike driven by a few large orders or broad growth?
**Finding:** The two largest individual orders in November (£52,940 and £50,653) stood out from the rest, but together they represented only ~7.2% of the month's total revenue (£103,594 of £1,433,882). This suggests the growth was broad-based, not concentrated in a handful of transactions. It contrasts with the returns outlier in section 2, where a single order accounted for effectively 100% of the anomaly.

### 6. Which customers are the most valuable?
**Finding:** I ranked customers by total spend, excluding ~20% of revenue tied to transactions with no CustomerID recorded (a data quality gap worth flagging on its own). I verified that the top two customers' totals came from genuine repeat purchasing (74 and 60 separate orders respectively), not a single bulk transaction.

I then calculated average order value as total spend ÷ number of distinct orders, not a plain `AVG()` on revenue, which would average per product line instead of per order. This showed that customers aren't valuable in the same way: some (e.g., Customer 12415, 24 orders, £5,151 average) are infrequent high-ticket buyers, while others (e.g., Customer 14911, 243 orders, £547 average) drive value through purchase frequency. This distinction matters for how a business would target retention versus acquisition for each group.

**Recommendation:**
1. Treat the two groups differently. Frequent buyers are best served with retention efforts such as reorder reminders or loyalty offers. High-value occasional buyers may be wholesale-type customers, so they may respond better to account management, bulk pricing or restock reminders. Check this before acting.
2. Investigate why about a fifth of revenue has no customer ID (guest checkout or recording errors) and report customer metrics with that gap stated. If it's guest checkout, consider an optional account step instead of a mandatory one, to avoid losing sales.

**Limitation:** Results describe the top customers by spend and exclude revenue with no customer ID, so they do not represent the whole customer base.

## Next steps
- Find reversal pairs automatically (match each return to an earlier sale of the same product, quantity and price) and re-run the return-rate ranking without them.
- Check the other top-ranked products for the same pairs before calling any of them a problem product.

## Tools
PostgreSQL, pgAdmin. SQL features used: regular expressions, date functions, CASE expressions, subqueries, `PERCENTILE_CONT`, aggregate `FILTER`.

## Files
- `sql/01_revenue_and_data_cleaning.sql` — revenue by product and country, filtering out non-product stock codes
- `sql/02_revenue_trends_and_orders.sql` — monthly revenue, revenue per day, data-coverage checks, November order concentration
- `sql/03_returns_and_outliers.sql` — return losses, the PAPER CRAFT outlier, percentile-based order-size buckets
- `sql/04_return_rate_analysis.sql` — return rate by product, order counts, checks on suspicious products
- `sql/05_customer_value.sql` — top customers, repeat orders, average order value
