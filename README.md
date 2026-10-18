# uk-retail-revenue-analysis

# UK Online Retail — SQL Revenue & Returns Analysis

## Overview
Analysis of a real e-commerce transaction dataset (UCI Online Retail, 
~540K rows) using PostgreSQL to  analyse: top-selling products, data 
quality issues, and returns impact on revenue.

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
The product with the largest apparent "return loss" 
(PAPER CRAFT, LITTLE BIRDIE, -£168K) turned out to be a single 
wholesale order of 80,995 units cancelled 12 minutes after purchase 
— not a genuine customer-return pattern. Traced the cancellation 
back to its matching original order to confirm, then excluded 
extreme-quantity returns to get a cleaner view of real returns 
behavior.

**3. Also found**: "REGENCY CAKESTAND 3 TIER" and "WHITE HANGING HEART 
T-LIGHT HOLDER" appear in both the top-revenue and top-returns 
lists — meaning gross revenue overstates their actual profitability.

**4**.Checked Revenue by country

**5**.**Revenue trend over time (by month)**:Revenue showed strong month-over-month growth through late 2011, peaking in November (£1.43M). December 2011 appears to show a sharp drop, but this is a data artifact — the dataset only contains records through December 9th, not the full month, so this isn’t a genuine decline.

**6**. **Also found**: Verified that September–November 2011 are complete months (consistent day coverage), confirming the revenue growth across this period is genuine — not an artifact of partial-month data, unlike December.

## Tools
PostgreSQL, pgAdmin

## Files
- `da_practice.sql` — all queries, in order, with comments
