/*==============================================================================
 PROJECT: SaaS Revenue & Customer Churn Analysis
 FILE:    02_exploratory_analysis.sql
 DATABASE: saas_revenue_churn_analysis
 ENGINE:  PostgreSQL 16

  PURPOSE
 -------
 Explore the analytics-ready datasets to understand customer composition,
 revenue characteristics, engagement behavior, churn patterns, customer
 lifecycle, and monthly business trends before formal business analysis.

 
 DATASETS
 --------
 analytics.subscriptions
     Grain: One row per customer

 analytics.monthly_revenue
     Grain: One row per reporting month

 NOTE
 ----
 This stage is exploratory.

 Final business KPIs, CLV/CAC analysis, formal at-risk customer rules,
 and business recommendations will be developed in:

 03_business_analysis.sql
==============================================================================*/


-- ============================================================================
-- 1. DATASET OVERVIEW
-- ============================================================================


-- --------------------------------------------------------------------------
-- 1.1 Customer dataset overview
-- --------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE is_churned = FALSE
    ) AS retained_customers,

    MIN(signup_date) AS earliest_signup_date,
    MAX(signup_date) AS latest_signup_date

FROM analytics.subscriptions;


/*
PURPOSE:
Understand the overall size and coverage of the customer dataset.

Questions:
- How many customers are available?
- How many are churned vs retained?
- What period does customer acquisition cover?
*/


-- --------------------------------------------------------------------------
-- 1.2 Monthly dataset overview
-- --------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_months,

    MIN(month) AS first_month,
    MAX(month) AS last_month,

    MIN(total_active_customers) AS min_active_customers,
    MAX(total_active_customers) AS max_active_customers,

    MIN(total_mrr) AS min_mrr,
    MAX(total_mrr) AS max_mrr

FROM analytics.monthly_revenue;


/*
PURPOSE:
Understand the time coverage and broad range of monthly business activity.
*/


-- --------------------------------------------------------------------------
-- 1.3 Verify customer-level grain
-- --------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers

FROM analytics.subscriptions;


/*
If both values are equal:

One row = one customer
*/


-- --------------------------------------------------------------------------
-- 1.4 Verify monthly grain
-- --------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT month) AS unique_months

FROM analytics.monthly_revenue;


/*
If both values are equal:

One row = one reporting month
*/
-- ============================================================================
-- 2. CUSTOMER COMPOSITION
-- ============================================================================

-- 2.1 Customers by subscription plan


SELECT
    plan,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY plan

ORDER BY customers DESC;


-- 2.2 Customers by billing cycle

SELECT
    billing_cycle,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY billing_cycle

ORDER BY customers DESC;


-- 2.3 Customers by company size

SELECT
    company_size,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY company_size

ORDER BY customers DESC;


-- 2.4 Customers by industry

SELECT
    industry,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY industry

ORDER BY customers DESC;


-- 2.5 Customers by acquisition channel

SELECT
    acquisition_channel,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY acquisition_channel

ORDER BY customers DESC;


-- 2.6 Customers by region

SELECT
    region,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY region

ORDER BY customers DESC;

-- ============================================================================
-- 3. REVENUE CHARACTERISTICS
-- ============================================================================

-- 3.1 Overall customer-level monthly revenue

SELECT
    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_revenue),
        2
    ) AS avg_monthly_revenue,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY monthly_revenue)::NUMERIC,
        2
    ) AS median_monthly_revenue,

    MIN(monthly_revenue) AS min_monthly_revenue,
    MAX(monthly_revenue) AS max_monthly_revenue,

    ROUND(
        STDDEV(monthly_revenue),
        2
    ) AS revenue_stddev

FROM analytics.subscriptions;


/*
PURPOSE:
Understand the distribution and variability of customer-level revenue.

Comparing average and median can help identify whether high-value accounts
are pulling the average upward.
*/


-- 3.2 Revenue characteristics by plan

SELECT
    plan,
    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_revenue),
        2
    ) AS avg_monthly_revenue,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY monthly_revenue)::NUMERIC,
        2
    ) AS median_monthly_revenue,

    MIN(monthly_revenue) AS min_monthly_revenue,
    MAX(monthly_revenue) AS max_monthly_revenue,

    ROUND(
        SUM(monthly_revenue),
        2
    ) AS customer_mrr_total

FROM analytics.subscriptions

GROUP BY plan

ORDER BY customer_mrr_total DESC;


/*

Understand how customer-level revenue differs across subscription plans.
*/


-- 3.3 Revenue contribution by plan

SELECT
    plan,

    ROUND(
        SUM(monthly_revenue),
        2
    ) AS customer_mrr_total,

    ROUND(
        100.0 * SUM(monthly_revenue)
        / NULLIF(SUM(SUM(monthly_revenue)) OVER (), 0),
        2
    ) AS revenue_share_pct

FROM analytics.subscriptions

GROUP BY plan

ORDER BY customer_mrr_total DESC;


/*

Determine which plans contribute the largest share of customer-level
monthly recurring revenue.
*/

-- ============================================================================
-- 4. CUSTOMER ENGAGEMENT
-- ============================================================================


-- 4.1 Overall engagement profile

SELECT
    ROUND(
        AVG(feature_usage_pct),
        2
    ) AS avg_feature_usage_pct,

    ROUND(
        AVG(nps_score),
        2
    ) AS avg_nps_score,

    ROUND(
        AVG(support_tickets_12mo),
        2
    ) AS avg_support_tickets_12mo

FROM analytics.subscriptions;


/*
:Establish baseline customer engagement and experience levels.
*/


-- 4.2 Engagement by subscription plan

SELECT
    plan,
    COUNT(*) AS customers,

    ROUND(
        AVG(feature_usage_pct),
        2
    ) AS avg_feature_usage_pct,

    ROUND(
        AVG(nps_score),
        2
    ) AS avg_nps_score,

    ROUND(
        AVG(support_tickets_12mo),
        2
    ) AS avg_support_tickets_12mo

FROM analytics.subscriptions

GROUP BY plan

ORDER BY plan;


/*
Explore whether customer engagement differs across subscription plans.
*/


-- 4.3 Feature usage distribution

SELECT
    MIN(feature_usage_pct) AS min_usage_pct,

    ROUND(
        AVG(feature_usage_pct),
        2
    ) AS avg_usage_pct,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY feature_usage_pct)::NUMERIC,
        2
    ) AS median_usage_pct,

    MAX(feature_usage_pct) AS max_usage_pct

FROM analytics.subscriptions;


/*

Understand the overall distribution of product feature usage.
*/


-- --------------------------------------------------------------------------
-- 4.4 NPS distribution
-- --------------------------------------------------------------------------

SELECT
    nps_score,
    COUNT(*) AS customers

FROM analytics.subscriptions

GROUP BY nps_score

ORDER BY nps_score;


/*

Explore how customer satisfaction scores are distributed.
*/


-- 4.5 Support ticket distribution

SELECT
    support_tickets_12mo,
    COUNT(*) AS customers

FROM analytics.subscriptions

GROUP BY support_tickets_12mo

ORDER BY support_tickets_12mo;


/*

Understand customer support interaction frequency.
*/


-- ============================================================================
-- 5. INITIAL CHURN EXPLORATION
-- ============================================================================


-- 5.1 Churn status distribution

SELECT
    CASE
        WHEN is_churned THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,

    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM analytics.subscriptions

GROUP BY is_churned

ORDER BY customers DESC;


/*

Understand the basic distribution of churned and retained customers.

The formal churn KPI and business interpretation will be handled in
03_business_analysis.sql.
*/


-- 5.2 Churn reason distribution

SELECT
    churn_reason,
    COUNT(*) AS churned_customers,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS share_of_churned_pct

FROM analytics.subscriptions

WHERE is_churned = TRUE

GROUP BY churn_reason

ORDER BY churned_customers DESC;


/*

Explore which reasons appear most frequently among churned customers.

The final Top 3 churn reasons will be formally reported in the business
analysis stage.
*/


-- ============================================================================
-- 6. CHURNED VS RETAINED CUSTOMER CHARACTERISTICS
-- ============================================================================


-- 6.1 Compare key characteristics by churn status

SELECT
    CASE
        WHEN is_churned THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_revenue),
        2
    ) AS avg_monthly_revenue,

    ROUND(
        AVG(feature_usage_pct),
        2
    ) AS avg_feature_usage_pct,

    ROUND(
        AVG(nps_score),
        2
    ) AS avg_nps_score,

    ROUND(
        AVG(support_tickets_12mo),
        2
    ) AS avg_support_tickets

FROM analytics.subscriptions

GROUP BY is_churned

ORDER BY is_churned DESC;


/*

Explore whether churned customers show different characteristics from
retained customers.

This is particularly important for later at-risk customer analysis.
*/


-- 6.2 Exploratory feature-usage bands

WITH usage_segments AS (

    SELECT
        CASE
            WHEN feature_usage_pct < 25 THEN 'Below 25%'
            WHEN feature_usage_pct < 50 THEN '25% - 49%'
            WHEN feature_usage_pct < 75 THEN '50% - 74%'
            ELSE '75%+'
        END AS usage_band,

        CASE
            WHEN feature_usage_pct < 25 THEN 1
            WHEN feature_usage_pct < 50 THEN 2
            WHEN feature_usage_pct < 75 THEN 3
            ELSE 4
        END AS usage_order,

        is_churned

    FROM analytics.subscriptions
)

SELECT
    usage_band,
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_share_pct

FROM usage_segments

GROUP BY
    usage_band,
    usage_order

ORDER BY usage_order;


/*
IMPORTANT:

These usage bands are EXPLORATORY ONLY.

They are NOT the official at-risk threshold.

We are testing whether lower product usage appears associated with higher
customer churn before defining any risk rule.
*/


-- 6.3 Churn pattern by NPS score

SELECT
    nps_score,
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_share_pct

FROM analytics.subscriptions

GROUP BY nps_score

ORDER BY nps_score;


/*

Explore whether lower customer satisfaction is associated with churn.
*/


-- 6.4 Churn pattern by support-ticket count

SELECT
    support_tickets_12mo,
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_share_pct

FROM analytics.subscriptions

GROUP BY support_tickets_12mo

ORDER BY support_tickets_12mo;


/*

Explore whether frequent support interactions are associated with churn.
*/


-- ============================================================================
-- 7. CUSTOMER LIFECYCLE
-- ============================================================================


-- 7.1 Customer signups by year

SELECT
    EXTRACT(YEAR FROM signup_date)::INTEGER AS signup_year,
    COUNT(*) AS new_customers

FROM analytics.subscriptions

GROUP BY signup_year

ORDER BY signup_year;


/*

Understand how customer acquisition changed across years.
*/


-- 7.2 Churned customers by year

SELECT
    EXTRACT(YEAR FROM churn_date)::INTEGER AS churn_year,
    COUNT(*) AS churned_customers

FROM analytics.subscriptions

WHERE is_churned = TRUE

GROUP BY churn_year

ORDER BY churn_year;


/*

Explore when churn events occurred across the available history.
*/


-- 7.3 Observed lifespan of churned customers

SELECT
    plan,

    COUNT(*) AS churned_customers,

    ROUND(
        AVG(
            EXTRACT(
                YEAR FROM AGE(churn_date, signup_date)
            ) * 12
            +
            EXTRACT(
                MONTH FROM AGE(churn_date, signup_date)
            )
        ),
        2
    ) AS avg_observed_lifespan_months

FROM analytics.subscriptions

WHERE
    is_churned = TRUE
    AND churn_date IS NOT NULL

GROUP BY plan

ORDER BY avg_observed_lifespan_months DESC;


/*

Explore observed customer lifespan among customers who actually churned.

IMPORTANT:
This is descriptive EDA, not yet the final CLV calculation.

Retained customers have not completed their customer lifetime, so their
lifetime cannot be treated the same way as churned customers without making
additional assumptions.
*/


-- ============================================================================
-- 8. MONTHLY CUSTOMER & REVENUE TRENDS
-- ============================================================================


-- 8.1 Monthly customer movement

SELECT
    month,
    total_active_customers,
    new_customers,
    churned_customers

FROM analytics.monthly_revenue

ORDER BY month;


/*

Observe how the active customer base, new customer acquisition, and customer
churn change over time.
*/


-- 8.2 Monthly MRR trend

SELECT
    month,
    total_mrr,

    LAG(total_mrr) OVER (
        ORDER BY month
    ) AS previous_month_mrr,

    ROUND(
        100.0
        * (
            total_mrr
            - LAG(total_mrr) OVER (ORDER BY month)
        )
        / NULLIF(
            LAG(total_mrr) OVER (ORDER BY month),
            0
        ),
        2
    ) AS mrr_growth_pct

FROM analytics.monthly_revenue

ORDER BY month;


/*

Explore recurring revenue growth and identify months with unusual changes.

LAG() allows each month to be compared with the previous month.
*/


-- 8.3 Monthly churn-rate trend

SELECT
    month,
    monthly_churn_rate_pct

FROM analytics.monthly_revenue

ORDER BY month;


/*

Observe whether monthly churn appears to improve, worsen, or fluctuate
over time.

Formal trend interpretation will be performed in business analysis.
*/


-- 8.4 Monthly ARPC trend

SELECT
    month,
    avg_revenue_per_customer

FROM analytics.monthly_revenue

ORDER BY month;


/*

Explore changes in average revenue generated per active customer.
*/


-- 8.5 Monthly CAC trend

SELECT
    month,
    customer_acquisition_cost

FROM analytics.monthly_revenue

ORDER BY month;


/*

Explore how customer acquisition cost changes over time.
*/


-- ============================================================================
-- 9. POTENTIAL UNUSUAL / EXTREME PERIODS
-- ============================================================================


-- 9.1 Months with highest churn rates

SELECT
    month,
    monthly_churn_rate_pct,
    churned_customers,
    total_active_customers

FROM analytics.monthly_revenue

ORDER BY monthly_churn_rate_pct DESC

LIMIT 5;


/*

Identify months that may require deeper investigation.
*/


-- 9.2 Months with largest MRR increases

WITH mrr_changes AS (

    SELECT
        month,
        total_mrr,

        LAG(total_mrr) OVER (
            ORDER BY month
        ) AS previous_month_mrr

    FROM analytics.monthly_revenue
)

SELECT
    month,
    previous_month_mrr,
    total_mrr,

    ROUND(
        total_mrr - previous_month_mrr,
        2
    ) AS mrr_change,

    ROUND(
        100.0
        * (total_mrr - previous_month_mrr)
        / NULLIF(previous_month_mrr, 0),
        2
    ) AS mrr_change_pct

FROM mrr_changes

WHERE previous_month_mrr IS NOT NULL

ORDER BY mrr_change DESC

LIMIT 5;


/*
Identify periods with the strongest absolute MRR growth.
*/


-- 9.3 Months with largest MRR declines

WITH mrr_changes AS (

    SELECT
        month,
        total_mrr,

        LAG(total_mrr) OVER (
            ORDER BY month
        ) AS previous_month_mrr

    FROM analytics.monthly_revenue
)

SELECT
    month,
    previous_month_mrr,
    total_mrr,

    ROUND(
        total_mrr - previous_month_mrr,
        2
    ) AS mrr_change,

    ROUND(
        100.0
        * (total_mrr - previous_month_mrr)
        / NULLIF(previous_month_mrr, 0),
        2
    ) AS mrr_change_pct

FROM mrr_changes

WHERE previous_month_mrr IS NOT NULL

ORDER BY mrr_change ASC

LIMIT 5;


/*

Identify periods where recurring revenue declined the most.
*/


-- 9.4 Months with highest customer acquisition

SELECT
    month,
    new_customers,
    total_active_customers,
    customer_acquisition_cost

FROM analytics.monthly_revenue

ORDER BY new_customers DESC

LIMIT 5;


/*

Identify periods with unusually strong customer acquisition.
*/


/*==============================================================================
 EDA COMPLETE

 
 BUSINESS QUESTIONS TO ANSWER NEXT
 ---------------------------------

 1. What is the overall churn rate and how has monthly churn changed over time?

 2. Which subscription plans have the highest churn?
    Does billing cycle affect retention?

 3. Which customer segments have the highest churn risk?

 4. What are the Top 3 churn reasons?
    Do churn reasons differ by plan or company size?

 5. How is MRR changing over time?

 6. What are the unit economics by plan?
    - Average customer revenue
    - Observed customer lifespan
    - CLV
    - CAC
    - CLV/CAC

 7. What evidence-based indicators can identify at-risk customers?

 8. How much revenue is associated with customers identified as at risk?

 IMPORTANT:
 Conclusions and recommendations should be based on the actual query results,
 not assumptions made before analysis.
==============================================================================*/
