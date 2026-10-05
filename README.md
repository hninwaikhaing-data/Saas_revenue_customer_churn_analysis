# SaaS Revenue & Customer Churn Analysis | PostgreSQL

## Project Overview

This project analyzes customer churn, recurring revenue performance, customer retention, and unit economics for a SaaS company using PostgreSQL.

The company has grown to 600 subscription records, but customer churn presents a risk to sustainable recurring-revenue growth. 
The analysis focuses on identifying high-churn customer segments, understanding the main reasons customers leave, evaluating revenue performance, and comparing customer lifetime value across subscription plans.

---

## Business Problem

The SaaS company has experienced customer growth, but customer churn threatens sustainable recurring-revenue performance.

Management needs to understand:

- How customer churn has changed over time
- Which subscription plans and billing cycles experience the highest churn
- Why customers leave
- Whether churn reasons differ across customer segments
- How recurring revenue is developing
- Which subscription plans generate the strongest customer lifetime value relative to acquisition cost

The goal is to translate customer and revenue data into actionable insights that support customer retention and revenue-quality decisions.

---

## Project Objectives

The objectives of this project are to:

- Measure overall and monthly customer churn
- Evaluate the four-year churn trend
- Identify high-churn subscription and billing segments
- Test the relationship between billing cycle and churn
- Identify the main reasons customers leave
- Compare churn reasons across plan types and company sizes
- Analyze recurring-revenue performance
- Estimate Customer Lifetime Value (CLV) by subscription plan
- Compare estimated CLV with Customer Acquisition Cost (CAC)
- Identify stronger and weaker customer unit economics
- Develop actionable recommendations for customer retention

---

## Business Questions

### BQ1 — Churn Performance

**What is the overall churn rate, and how has the monthly churn rate trended over the past four years? Is churn improving or getting worse?**

### BQ2 — Churn by Customer Segment

**Which subscription plan (Starter, Professional, Business, Enterprise) has the highest churn rate? Does billing cycle (monthly vs. annual) significantly impact retention?**

### BQ3 — Churn Reasons

**What are the top three reasons customers churn, and do these reasons differ by plan type or company size?**

### BQ4 — Revenue Performance Analysis

Analyze recurring-revenue performance, including:

- Monthly MRR growth
- Annual MRR performance
- Customer movement and MRR
- Largest monthly MRR changes

### BQ5 — Customer Lifetime Value & Unit Economics

**Calculate average Customer Lifetime Value (CLV) by plan and compare it with Customer Acquisition Cost (CAC). Which plans demonstrate the strongest and weakest unit economics?**

---

## Dataset

The project uses two datasets.

### `subscriptions.csv`

Customer-level subscription data containing 600 customer records.

Key fields include:

- Customer ID
- Subscription plan
- Billing cycle
- Industry
- Company size
- Seats
- Monthly revenue
- Acquisition channel
- Region
- Signup date
- Churn status
- Churn date
- Churn reason
- Support tickets
- NPS score
- Feature usage
- Upgrade status

### `monthly_revenue.csv`

Monthly company-level revenue and customer metrics covering **January 2022 through December 2025**.

Key fields include:

- Month
- Active customers
- New customers
- Churned customers
- Monthly churn rate
- Monthly Recurring Revenue (MRR)
- Average revenue per customer
- Customer Acquisition Cost (CAC)

---

## Tools & Technologies

- **PostgreSQL 16** — Data processing, exploration, analysis, KPI calculation, and statistical analysis
- **pgAdmin 4** — Database management and SQL execution
- **VS Code** — SQL development and project documentation
- **Git & GitHub** — Version control and project portfolio

---

## Project Workflow

```text
Raw Data
   ↓
Data Processing
   ↓
Exploratory Data Analysis
   ↓
Business Analysis
   ↓
Business Insights
   ↓
Recommendations
```

---

## Data Processing

Raw datasets were loaded into a dedicated `raw` schema to preserve the original source data.

Clean analytical tables were then created in the `analytics` schema.

Key processing tasks included:

- Data type validation
- Date conversion
- Boolean conversion for churn and upgrade status
- NULL validation
- Duplicate validation
- Primary-key validation
- Business-rule validation
- Analytical table creation

Structural NULL values in `churn_date` and `churn_reason` were preserved because they represent customers who had not churned rather than missing data requiring imputation.

---

## Exploratory Data Analysis

EDA was performed before answering the business questions to understand the structure, quality, and characteristics of the data.

The exploration included:

- Dataset overview and grain validation
- Customer composition
- Revenue characteristics
- Customer engagement
- Initial churn exploration
- Churned vs. retained customer comparison
- Customer lifecycle
- Monthly customer and revenue trends
- Review of unusual or extreme periods

---

# Business Analysis

## BQ1 — Churn Performance

The customer dataset contains:

- **600 total customers**
- **313 churned customers**
- **287 retained customers**
- **52.17% overall observed churn share**

Average monthly churn changed as follows:

| Year | Average Monthly Churn Rate |
|---|---:|
| 2022 | 6.81% |
| 2023 | 4.12% |
| 2024 | 3.56% |
| 2025 | 3.60% |

### Key Finding

Customer retention improved substantially over the analysis period. Average monthly churn declined from **6.81% in 2022 to 3.56% in 2024**.

However, churn increased slightly to **3.60% in 2025**, indicating that the previous improvement may have begun to stabilize rather than continuing downward.

### Business Impact

The reduction in monthly churn indicates stronger customer retention compared with the company's earlier years.

However, the stabilization in 2025 means retention should remain a management priority. Continued monitoring is needed to determine whether the recent change represents normal variation or the beginning of a worsening trend.

---

## BQ2 — Churn by Customer Segment

### Churn by Subscription Plan

| Plan | Customers | Churned | Churn Rate |
|---|---:|---:|---:|
| Starter | 217 | 153 | 70.51% |
| Professional | 173 | 83 | 47.98% |
| Business | 160 | 66 | 41.25% |
| Enterprise | 50 | 11 | 22.00% |

Starter has the highest observed churn rate, while Enterprise has the lowest.

### Churn by Billing Cycle

| Billing Cycle | Customers | Churned | Churn Rate |
|---|---:|---:|---:|
| Monthly | 352 | 213 | 60.51% |
| Annual | 248 | 100 | 40.32% |

Monthly subscribers experience a churn rate **20.19 percentage points higher** than annual subscribers.

A chi-square test was used to evaluate the relationship between billing cycle and churn.

**Chi-square statistic: 23.7651**

At a 5% significance level with one degree of freedom, this exceeds the critical value of 3.841.

### Key Finding

Starter represents the highest-churn subscription segment at **70.51%**.

Annual customers demonstrate considerably stronger retention than monthly customers. The statistical test indicates that billing cycle and churn are significantly associated in this dataset.

### Business Impact

Starter customers represent an important retention opportunity because the plan combines the largest customer base with the highest churn rate.

The significant difference between monthly and annual customer retention also suggests that billing structure should be considered when developing retention strategies.

The analysis establishes an association rather than proving that billing cycle directly causes churn.

---

## BQ3 — Churn Reasons

The top three overall churn reasons are:

| Churn Reason | Customers | Share of Churn |
|---|---:|---:|
| Budget Cuts | 53 | 16.93% |
| Price Too High | 51 | 16.29% |
| Company Closed | 48 | 15.34% |

Together, these reasons account for **48.56% of recorded churn**.

### Key Finding

No single reason dominates customer churn.

Financial and business-condition factors are important overall, but the leading reasons also differ across customer segments.

For example:

- Among companies with **1–10 employees**, Budget Cuts and Price Too High are particularly prominent.
- Among companies with **11–50 employees**, No Longer Needed is the leading reason.
- Among **Business-plan customers**, Missing Features is the leading churn reason.

### Business Impact

A single retention strategy is unlikely to address the full churn problem.

Different customer groups leave for different reasons, meaning retention initiatives should be tailored according to customer needs, financial pressure, product relevance, and feature requirements.

---

## BQ4 — Revenue Performance Analysis

Recurring-revenue performance was analyzed using monthly and annual revenue data.

The analysis includes:

- Month-over-month MRR growth
- Annual MRR performance
- New and churned customer movement
- Net customer change
- Active customer trends
- Largest monthly increases and decreases in MRR

Detailed SQL queries for this analysis are available in:

`sql/03_business_analysis.sql`

---

## BQ5 — Customer Lifetime Value & Unit Economics

Estimated CLV was calculated using:

```text
Estimated CLV = Average Monthly Revenue × Average Observed Customer Lifespan
```

### Estimated CLV by Plan

| Plan | Avg. Observed Lifespan | Avg. Monthly Revenue | Estimated CLV |
|---|---:|---:|---:|
| Enterprise | 14.75 months | 2,984.99 | 44,042.21 |
| Business | 14.66 months | 1,303.64 | 19,104.86 |
| Professional | 10.70 months | 497.04 | 5,315.95 |
| Starter | 6.74 months | 215.54 | 1,452.64 |

The company-wide average CAC is **200.04**.

### CLV:CAC Comparison

| Plan | Estimated CLV | CAC Benchmark | CLV:CAC |
|---|---:|---:|---:|
| Enterprise | 44,042.21 | 200.04 | 220.17 |
| Business | 19,104.86 | 200.04 | 95.50 |
| Professional | 5,315.95 | 200.04 | 26.57 |
| Starter | 1,452.64 | 200.04 | 7.26 |

### Key Finding

Enterprise demonstrates the strongest unit economics, with the highest estimated CLV and CLV:CAC ratio.

Starter demonstrates the weakest unit economics, with the shortest observed customer lifespan and lowest estimated CLV.

### Business Impact

Enterprise and Business customers represent substantially greater estimated long-term customer value and should receive strong retention attention.

Starter has the largest customer base but relatively low estimated lifetime value and high churn. Improving Starter retention and customer lifespan could therefore increase the economic value generated from this large customer segment.

---
 # Business Insights & Recommendations
  1. Customer churn has improved, but progress has stabilized
  Business Insight:
  Customer retention improved substantially over the four-year period. Average monthly churn declined from 6.81% in 2022 to 3.56% in 2024, before increasing slightly to 3.60% in 2025. Although churn is much lower than in the earlier period, the improvement appears to have leveled off.
  Recommendation:
  Continue monitoring monthly churn and investigate the periods or customer segments contributing to the 2025 stabilization. Retention initiatives should focus on preventing the earlier improvement from reversing.
  ________________________________________
  2. Starter customers are the highest-risk subscription segment
  Business Insight:
  The Starter plan has the highest churn rate at 70.51%, compared with Professional at 47.98%, Business at 41.25%, and Enterprise at only 22.00%. Starter also represents the largest customer group, making its high churn particularly important to overall retention performance.
  Recommendation:
  Prioritize the Starter segment for retention analysis. Investigate onboarding experience, product value, pricing concerns, feature limitations, and customer engagement to identify opportunities to improve retention.
  ________________________________________
  3. Annual subscribers demonstrate significantly stronger retention
  Business Insight:
  Monthly subscribers have a 60.51% churn rate, compared with 40.32% for annual subscribers, a difference of 20.19 percentage points. The chi-square statistic of 23.7651 confirms a statistically significant association between billing cycle and churn.
  Recommendation:
  Encourage suitable monthly customers to transition to annual subscriptions through annual-plan value communication, appropriate incentives, or renewal offers. Continue tracking churn by billing cycle to measure whether these initiatives improve retention.
  This relationship should be treated as an association; the analysis does not establish that annual billing itself causes better retention.
  ________________________________________
  4. Churn is driven by multiple factors, requiring targeted retention strategies
  Business Insight:
  The top three overall churn reasons are Budget Cuts (16.93%), Price Too High (16.29%), and Company Closed (15.34%), together accounting for 48.56% of recorded churn. However, the leading reasons differ across customer segments. For example, financial pressure is particularly prominent among smaller companies, while Missing Features is the leading reason among Business-plan customers.
  Recommendation:
  Avoid using one retention strategy for every customer. Develop segment-specific approaches: address pricing and value concerns for financially sensitive customers, while using product feedback and feature-gap analysis for segments where product capability is a stronger churn driver.
  ________________________________________
  5. High-value plans should receive greater retention protection
  Business Insight:
  Enterprise has the highest estimated CLV at 44,042.21, followed by Business at 19,104.86, Professional at 5,315.95, and Starter at 1,452.64. Against the company-wide average CAC benchmark of 200.04, Enterprise also has the strongest estimated CLV:CAC ratio at 220.17, while Starter has the weakest at 7.26.
  Recommendation:
  Protect Enterprise and Business customers through proactive retention monitoring because losing these customers puts substantially more lifetime revenue at risk. At the same time, investigate opportunities to increase Starter customer lifespan because the plan combines a large customer base with high churn and relatively low lifetime value.
  ________________________________________
 
  The analysis shows that SaaS customer retention has improved substantially over time, but churn remains concentrated in specific customer segments. Starter and monthly subscribers represent the clearest retention challenges, while churn drivers vary across customer groups and require targeted rather than uniform interventions. Enterprise and Business customers generate substantially greater estimated lifetime value, making their retention especially important to long-term revenue quality. A balanced retention strategy should therefore protect high-value customers while improving the experience, engagement, and lifetime value of the large Starter customer base.

---
# Repository Structure

```text
SaaS-Revenue-Churn-Analysis/
│
├── data/
│   ├── subscriptions.csv
│   └── monthly_revenue.csv
│
├── sql/
│   ├── 01_data_processing.sql
│   ├── 02_exploratory_analysis.sql
│   └── 03_business_analysis.sql
│
└── README.md
```

---

# Conclusion

The analysis shows that customer retention has improved substantially over time, but churn remains concentrated in specific customer segments.

Starter and monthly subscribers represent the clearest retention challenges, while the reasons customers leave vary across customer groups. Enterprise and Business customers generate substantially greater estimated lifetime value, making retention of these customers particularly important to long-term revenue quality.

The findings support a targeted retention strategy that protects high-value customers while improving customer lifetime and retention within the large Starter customer base.
