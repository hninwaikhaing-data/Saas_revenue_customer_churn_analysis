/*==============================================================================
 PROJECT: SaaS Revenue & Customer Churn Analysis
 FILE:    03_business_analysis.sql
 DATABASE: saas_revenue_churn_analysis
 ENGINE:  PostgreSQL 16

 PURPOSE
 -------
 Answer the core stakeholder business questions using the processed and
 explored SaaS customer and revenue data.

 BUSINESS QUESTIONS
 ------------------
 BQ1.What is the overall churn rate, and 
 	how has the monthly churn rate trended over the past 4 years? Is churn improving or getting worse?

 BQ2. Which subscription plan (Starter, Professional, Business, Enterprise) has the highest churn rate? 
 		Does billing cycle (monthly vs. annual) significantly impact retention?
      - Subscription plan
      - Billing cycle
      - Company size
      - Acquisition channel

 BQ3. What are the top 3 reasons customers churn, and do these reasons differ by plan type or company size?
      - Top churn reasons
      - Churn reasons by plan
      - Churn reasons by company size

 BQ4. How is recurring revenue performing over time?

 BQ5. What are the unit economics by subscription plan? Which plans are the most and least profitable?
      - Average monthly revenue
      - Customer lifespan
      - CLV
      - CAC
      - CLV/CAC


==============================================================================*/
-- ============================================================================
-- BQ1. OVERALL CHURN PERFORMANCE
-- ============================================================================

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE is_churned = FALSE
    ) AS retained_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS overall_churn_rate_pct

FROM analytics.subscriptions;

-- Monthly churn trend

SELECT
    month,
    total_active_customers,
    churned_customers,
    monthly_churn_rate_pct

FROM analytics.monthly_revenue

ORDER BY month;

-- BQ1.3 Annual churn trend


WITH monthly_churn AS (
    SELECT
        EXTRACT(YEAR FROM month)::INTEGER AS year,
        monthly_churn_rate_pct
    FROM analytics.monthly_revenue
)

SELECT
    year,

    ROUND(
        AVG(monthly_churn_rate_pct),
        2
    ) AS avg_monthly_churn_rate_pct,

    MIN(monthly_churn_rate_pct) AS lowest_monthly_churn_rate_pct,

    MAX(monthly_churn_rate_pct) AS highest_monthly_churn_rate_pct

FROM monthly_churn

GROUP BY year

ORDER BY year;
/*
===============================================================================
BQ1 BUSINESS ANSWER
===============================================================================

KEY FINDING:
- The overall observed churn rate is 52.17%, with 313 of 600 customers
  recorded as churned.

- Average monthly churn improved substantially over the four-year period,
  declining from 6.81% in 2022 to 4.12% in 2023 and 3.56% in 2024.

- In 2025, average monthly churn increased slightly to 3.60%.

- Overall, churn has improved considerably compared with 2022, but the
  improvement appears to have leveled off in 2025 rather than continuing
  to decline.


BUSINESS IMPACT:
- The substantial decline in monthly churn since 2022 indicates stronger
  customer retention as the business has grown.

- However, the slight increase in 2025 suggests that the business should
  continue monitoring retention rather than assuming churn will keep
  improving.

- With 313 customers already recorded as churned, retention remains an
  important business priority even though recent monthly churn rates are
  considerably lower than in the earlier period.


*/
-- ============================================================================
-- BQ2. CHURN BY CUSTOMER SEGMENT
-- ============================================================================

-- BQ2.1 Churn by subscription plan

SELECT
    plan,
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE is_churned = FALSE
    ) AS retained_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM analytics.subscriptions

GROUP BY plan

ORDER BY churn_rate_pct DESC;
/*
KEY FINDING:
- Starter recorded the highest churn rate at 70.51% (153 of 217 customers),
  followed by Professional at 47.98%, Business at 41.25%, and Enterprise
  at 22.00%.
- Churn consistently decreases across higher-tier subscription plans.

MEANINGFUL INSIGHT:
- Starter is the most important retention concern because it combines the
  largest customer base with the highest churn rate.
- The substantially lower churn among higher-tier plans suggests that
  stronger retention is associated with customers on higher-value plans.
- Further analysis of Starter customers is needed to determine what is
  driving their unusually high churn.
*/

-- BQ2.2 Churn by billing cycle

SELECT
    billing_cycle,
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE is_churned = FALSE
    ) AS retained_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM analytics.subscriptions

GROUP BY billing_cycle

ORDER BY churn_rate_pct DESC;
/*
KEY FINDING:
- Monthly subscribers recorded a churn rate of 60.51%, compared with
  40.32% for annual subscribers.
- Monthly billing therefore has a 20.19 percentage-point higher churn rate
  than annual billing.

*/
-- ============================================================================
-- BQ2.3 Statistical Significance: Billing Cycle vs Churn
-- Purpose:
-- Test whether billing cycle and customer churn are statistically associated.
--
-- H0: Billing cycle and churn are independent.
-- H1: Billing cycle and churn are associated.
-- ============================================================================

WITH observed AS (
    SELECT
        billing_cycle,
        COUNT(*) FILTER (WHERE is_churned = TRUE)  AS churned,
        COUNT(*) FILTER (WHERE is_churned = FALSE) AS retained
    FROM analytics.subscriptions
    GROUP BY billing_cycle
),

totals AS (
    SELECT
        SUM(churned) AS total_churned,
        SUM(retained) AS total_retained,
        SUM(churned + retained) AS grand_total
    FROM observed
),

expected AS (
    SELECT
        o.billing_cycle,
        o.churned,
        o.retained,

        (o.churned + o.retained)
            * t.total_churned::NUMERIC
            / t.grand_total AS expected_churned,

        (o.churned + o.retained)
            * t.total_retained::NUMERIC
            / t.grand_total AS expected_retained

    FROM observed o
    CROSS JOIN totals t
)

SELECT
    ROUND(
        SUM(
            POWER(churned - expected_churned, 2)
            / NULLIF(expected_churned, 0)
            +
            POWER(retained - expected_retained, 2)
            / NULLIF(expected_retained, 0)
        ),
        4
    ) AS chi_square_statistic
FROM expected;

-- Churn by company size

SELECT
    company_size,
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE is_churned = FALSE
    ) AS retained_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM analytics.subscriptions

GROUP BY company_size

ORDER BY churn_rate_pct DESC;
/*
KEY FINDING:
- The 500+ employee segment recorded the highest churn rate at 63.16%,
  followed by companies with 1-10 employees at 56.69%.
- The 51-200 employee segment recorded the lowest churn rate at 42.55%.
- Churn does not consistently increase or decrease with company size.


*/

-- BQ2.4 Churn by acquisition channel

SELECT
    acquisition_channel,
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_churned = TRUE
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE is_churned = FALSE
    ) AS retained_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE is_churned = TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM analytics.subscriptions

GROUP BY acquisition_channel

ORDER BY churn_rate_pct DESC;
/*
KEY FINDING:
- Referral customers recorded the highest churn rate at 61.29%, followed
  by Partner at 58.00% and Social Media at 55.77%.
- Direct Sales recorded the lowest churn rate at 39.29%, followed by
  Organic Search at 43.79%.
- There is a 22.00 percentage-point churn gap between Referral and
  Direct Sales customers.

*/

/*
/*
===============================================================================
BQ2 — KEY FINDING
===============================================================================

- Starter has the highest churn rate among all subscription plans at 70.51%,
  while Enterprise has the lowest churn rate at 22.00%.

- Monthly subscribers have a churn rate of 60.51%, compared with 40.32%
  for annual subscribers, a difference of 20.19 percentage points.

- The chi-square test produced a statistic of 23.7651, which is greater
  than the critical value of 3.841 at the 5% significance level.

- Therefore, the null hypothesis is rejected. Billing cycle and customer
  churn are statistically associated.

- Annual subscribers show significantly stronger retention than monthly
  subscribers in this dataset.


===============================================================================
BUSINESS IMPACT
===============================================================================

- Starter customers represent the greatest plan-level retention challenge
  because they have the highest observed churn rate.

- Monthly subscribers are also a higher-risk customer group, with churn
  substantially higher than among annual subscribers.

- The statistically significant relationship between billing cycle and
  churn suggests that billing structure is an important factor to consider
  when developing retention strategies.

- Increasing annual-plan adoption could potentially support stronger
  customer retention, although the analysis does not establish that annual
  billing itself causes lower churn.


*/
*/

-- ============================================================================
-- BQ3. WHY ARE CUSTOMERS LEAVING?
-- ============================================================================


-- BQ3.1 Overall churn reasons

SELECT
    churn_reason,
    COUNT(*) AS churned_customers,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS share_of_churn_pct

FROM analytics.subscriptions

WHERE is_churned = TRUE

GROUP BY churn_reason

ORDER BY churned_customers DESC;

-- BQ3.2 Top 3 churn reasons

SELECT
    churn_reason,
    COUNT(*) AS churned_customers,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS share_of_churn_pct

FROM analytics.subscriptions

WHERE is_churned = TRUE

GROUP BY churn_reason

ORDER BY churned_customers DESC

LIMIT 3;

/*
KEY FINDING:
- Budget Cuts was the most common churn reason, accounting for 53 customers
  (16.93% of all churn), followed closely by Price Too High at 16.29%
  and Company Closed at 15.34%.
- The Top 3 reasons collectively account for 48.56% of recorded churn.

*/

-- BQ3.3 Churn reasons by subscription plan

SELECT
    plan,
    churn_reason,
    COUNT(*) AS churned_customers,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            SUM(COUNT(*)) OVER (PARTITION BY plan),
            0
        ),
        2
    ) AS share_within_plan_pct

FROM analytics.subscriptions

WHERE is_churned = TRUE

GROUP BY
    plan,
    churn_reason

ORDER BY
    plan,
    churned_customers DESC;

/*
KEY FINDING:
- Churn reasons vary across subscription plans rather than following the
  same distribution for every plan.
- Within the Business plan, Missing Features is the leading churn reason
  at 18.18%, followed by Poor Support and No Longer Needed at 16.67% each.


*/
	
-- BQ3.4 Churn reasons by company size

SELECT
    company_size,
    churn_reason,
    COUNT(*) AS churned_customers,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            SUM(COUNT(*)) OVER (PARTITION BY company_size),
            0
        ),
        2
    ) AS share_within_company_size_pct

FROM analytics.subscriptions

WHERE is_churned = TRUE

GROUP BY
    company_size,
    churn_reason

ORDER BY
    company_size,
    churned_customers DESC;

/*
KEY FINDING:
- Churn reasons also differ across company-size segments.
- Among companies with 1-10 employees, Budget Cuts is the leading churn
  reason at 22.47%, followed by Price Too High at 17.98%.
- Financial pressures therefore account for the two most common reasons
  within the smallest company segment.

*/

-- BQ3.5 Top 3 churn reasons by subscription plan

WITH reason_counts AS (
    SELECT
        plan,
        churn_reason,
        COUNT(*) AS churned_customers

    FROM analytics.subscriptions

    WHERE is_churned = TRUE

    GROUP BY
        plan,
        churn_reason
),

ranked_reasons AS (
    SELECT
        plan,
        churn_reason,
        churned_customers,

        ROUND(
            100.0 * churned_customers
            / NULLIF(
                SUM(churned_customers) OVER (PARTITION BY plan),
                0
            ),
            2
        ) AS share_within_plan_pct,

        DENSE_RANK() OVER (
            PARTITION BY plan
            ORDER BY churned_customers DESC
        ) AS reason_rank

    FROM reason_counts
)

SELECT
    plan,
    reason_rank,
    churn_reason,
    churned_customers,
    share_within_plan_pct

FROM ranked_reasons

WHERE reason_rank <= 3

ORDER BY
    plan,
    reason_rank,
    churn_reason;

-- BQ3.6 Top 3 churn reasons by company size

WITH reason_counts AS (
    SELECT
        company_size,
        churn_reason,
        COUNT(*) AS churned_customers

    FROM analytics.subscriptions

    WHERE is_churned = TRUE

    GROUP BY
        company_size,
        churn_reason
),

ranked_reasons AS (
    SELECT
        company_size,
        churn_reason,
        churned_customers,

        ROUND(
            100.0 * churned_customers
            / NULLIF(
                SUM(churned_customers) OVER (
                    PARTITION BY company_size
                ),
                0
            ),
            2
        ) AS share_within_company_size_pct,

        DENSE_RANK() OVER (
            PARTITION BY company_size
            ORDER BY churned_customers DESC
        ) AS reason_rank

    FROM reason_counts
)

SELECT
    company_size,
    reason_rank,
    churn_reason,
    churned_customers,
    share_within_company_size_pct

FROM ranked_reasons

WHERE reason_rank <= 3

ORDER BY
    company_size,
    reason_rank,
    churn_reason;

/*
===============================================================================
BQ3 — KEY FINDING
===============================================================================

- The top three overall reasons for customer churn are Budget Cuts
  (16.93%), Price Too High (16.29%), and Company Closed (15.34%).

- Together, these three reasons account for 48.56% of recorded customer
  churn, showing that financial and business-condition factors contribute
  substantially to customer loss.

- However, no single churn reason dominates overall churn. The largest
  individual reason, Budget Cuts, represents only 16.93%, indicating that
  customer churn is driven by multiple factors.

- Churn reasons also differ across customer segments. For example, among
  companies with 1-10 employees, Budget Cuts (22.47%) and Price Too High
  (17.98%) are the leading reasons, showing stronger financial pressure
  within this segment.

- Among companies with 11-50 employees, No Longer Needed (18.28%) is the
  leading reason, suggesting that product relevance is a more prominent
  issue for this segment.

- Among Business-plan customers, Missing Features (18.18%) is the leading
  churn reason, indicating that product capability is an important
  retention concern for this plan.

- Overall, the analysis shows that customers do not leave for the same
  reasons across all plan types and company sizes.


===============================================================================
BUSINESS IMPACT
===============================================================================

- Because churn is distributed across several reasons, the business is
  unlikely to reduce churn effectively with a single retention strategy.

- Price and budget concerns are particularly important for some customer
  groups, especially smaller companies. Pricing flexibility, plan
  suitability, or value communication may therefore be important areas
  to investigate for these customers.

- Product-related issues also matter. Missing Features being the leading
  reason among Business-plan customers suggests that product capability
  can affect the retention of higher-value customers.

- Customers leaving because the product is No Longer Needed indicate that
  retention is not only a pricing issue. Continued product relevance and
  customer engagement should also be considered.

- Retention strategies should therefore be tailored by customer segment:
  financial concerns, product capability, customer needs, and other churn
  drivers should be addressed according to the segments where they are
  most prominent.
*/
-- ============================================================================
-- BQ4. REVENUE PERFORMANCE
-- ============================================================================

-- --------------------------------------------------------------------------
-- BQ4.1 Monthly MRR growth
-- --------------------------------------------------------------------------

WITH monthly_mrr AS (
    SELECT
        month,
        total_mrr,
        LAG(total_mrr) OVER (ORDER BY month) AS previous_month_mrr
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
        100.0 * (total_mrr - previous_month_mrr)
        / NULLIF(previous_month_mrr, 0),
        2
    ) AS mrr_growth_pct

FROM monthly_mrr

ORDER BY month;

-- --------------------------------------------------------------------------
-- BQ4.2 Annual MRR performance
-- --------------------------------------------------------------------------

WITH yearly_mrr AS (
    SELECT
        EXTRACT(YEAR FROM month)::INTEGER AS year,
        MIN(month) AS first_month,
        MAX(month) AS last_month
    FROM analytics.monthly_revenue
    GROUP BY EXTRACT(YEAR FROM month)::INTEGER
)

SELECT
    y.year,
    start_m.total_mrr AS starting_mrr,
    end_m.total_mrr AS ending_mrr,

    ROUND(
        end_m.total_mrr - start_m.total_mrr,
        2
    ) AS annual_mrr_change

FROM yearly_mrr y

JOIN analytics.monthly_revenue start_m
    ON start_m.month = y.first_month

JOIN analytics.monthly_revenue end_m
    ON end_m.month = y.last_month

ORDER BY y.year;

-- --------------------------------------------------------------------------
-- BQ4.3 Customer movement and MRR
-- --------------------------------------------------------------------------

SELECT
    month,
    new_customers,
    churned_customers,

    new_customers - churned_customers
        AS net_customer_change,

    total_active_customers,
    total_mrr

FROM analytics.monthly_revenue

ORDER BY month;

-- --------------------------------------------------------------------------
-- BQ4.4 Largest monthly MRR changes
-- --------------------------------------------------------------------------

WITH mrr_changes AS (
    SELECT
        month,
        total_mrr,
        LAG(total_mrr) OVER (ORDER BY month) AS previous_month_mrr
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
        100.0 * (total_mrr - previous_month_mrr)
        / NULLIF(previous_month_mrr, 0),
        2
    ) AS mrr_growth_pct

FROM mrr_changes

WHERE previous_month_mrr > 0

ORDER BY ABS(total_mrr - previous_month_mrr) DESC

LIMIT 10;


-- ============================================================================
-- BQ5. UNIT ECONOMICS BY SUBSCRIPTION PLAN
-- ============================================================================

-- --------------------------------------------------------------------------
-- BQ5.1 Average observed customer lifespan by plan
-- --------------------------------------------------------------------------

WITH churned_lifespans AS (
    SELECT
        plan,

        (
            EXTRACT(YEAR FROM AGE(churn_date, signup_date)) * 12
            + EXTRACT(MONTH FROM AGE(churn_date, signup_date))
            + EXTRACT(DAY FROM AGE(churn_date, signup_date)) / 30.0
        ) AS lifespan_months

    FROM analytics.subscriptions

    WHERE
        is_churned = TRUE
        AND churn_date IS NOT NULL
)

SELECT
    plan,
    COUNT(*) AS churned_customers,

    ROUND(
        AVG(lifespan_months),
        2
    ) AS avg_observed_lifespan_months

FROM churned_lifespans

GROUP BY plan

ORDER BY avg_observed_lifespan_months DESC;

-- --------------------------------------------------------------------------
-- BQ5.2 Average monthly revenue by plan
-- --------------------------------------------------------------------------

SELECT
    plan,
    COUNT(*) AS total_customers,

    ROUND(
        AVG(monthly_revenue),
        2
    ) AS avg_monthly_revenue

FROM analytics.subscriptions

GROUP BY plan

ORDER BY avg_monthly_revenue DESC;

-- --------------------------------------------------------------------------
-- BQ5.3 Estimated CLV by subscription plan
-- --------------------------------------------------------------------------

WITH plan_revenue AS (
    SELECT
        plan,
        AVG(monthly_revenue) AS avg_monthly_revenue

    FROM analytics.subscriptions

    GROUP BY plan
),

plan_lifespan AS (
    SELECT
        plan,

        AVG(
            EXTRACT(YEAR FROM AGE(churn_date, signup_date)) * 12
            + EXTRACT(MONTH FROM AGE(churn_date, signup_date))
            + EXTRACT(DAY FROM AGE(churn_date, signup_date)) / 30.0
        ) AS avg_observed_lifespan_months

    FROM analytics.subscriptions

    WHERE
        is_churned = TRUE
        AND churn_date IS NOT NULL

    GROUP BY plan
)

SELECT
    r.plan,

    ROUND(
        r.avg_monthly_revenue,
        2
    ) AS avg_monthly_revenue,

    ROUND(
        l.avg_observed_lifespan_months,
        2
    ) AS avg_observed_lifespan_months,

    ROUND(
        r.avg_monthly_revenue
        * l.avg_observed_lifespan_months,
        2
    ) AS estimated_clv

FROM plan_revenue r

JOIN plan_lifespan l
    ON r.plan = l.plan

ORDER BY estimated_clv DESC;


-- BQ5.4 Overall customer acquisition cost

SELECT
    ROUND(
        AVG(customer_acquisition_cost),
        2
    ) AS avg_customer_acquisition_cost,

    MIN(customer_acquisition_cost) AS min_customer_acquisition_cost,
    MAX(customer_acquisition_cost) AS max_customer_acquisition_cost

FROM analytics.monthly_revenue;

-- BQ5.5 Estimated CLV vs company-wide average CAC

WITH plan_revenue AS (
    SELECT
        plan,
        AVG(monthly_revenue) AS avg_monthly_revenue
    FROM analytics.subscriptions
    GROUP BY plan
),

plan_lifespan AS (
    SELECT
        plan,
        AVG(
            EXTRACT(YEAR FROM AGE(churn_date, signup_date)) * 12
            + EXTRACT(MONTH FROM AGE(churn_date, signup_date))
            + EXTRACT(DAY FROM AGE(churn_date, signup_date)) / 30.0
        ) AS avg_observed_lifespan_months
    FROM analytics.subscriptions
    WHERE
        is_churned = TRUE
        AND churn_date IS NOT NULL
    GROUP BY plan
),

company_cac AS (
    SELECT
        AVG(customer_acquisition_cost) AS avg_cac
    FROM analytics.monthly_revenue
),

unit_economics AS (
    SELECT
        r.plan,
        r.avg_monthly_revenue,
        l.avg_observed_lifespan_months,

        r.avg_monthly_revenue
        * l.avg_observed_lifespan_months AS estimated_clv,

        c.avg_cac

    FROM plan_revenue r

    JOIN plan_lifespan l
        ON r.plan = l.plan

    CROSS JOIN company_cac c
)

SELECT
    plan,

    ROUND(avg_monthly_revenue, 2)
        AS avg_monthly_revenue,

    ROUND(avg_observed_lifespan_months, 2)
        AS avg_observed_lifespan_months,

    ROUND(estimated_clv, 2)
        AS estimated_clv,

    ROUND(avg_cac, 2)
        AS avg_company_cac,

    ROUND(
        estimated_clv / NULLIF(avg_cac, 0),
        2
    ) AS clv_to_cac_ratio

FROM unit_economics

ORDER BY clv_to_cac_ratio DESC;


-- --------------------------------------------------------------------------
-- BQ5.6 Rank plans by unit economics
-- Business requirement:
-- Which plans are the most and least profitable?
-- --------------------------------------------------------------------------

WITH plan_revenue AS (
    SELECT
        plan,
        AVG(monthly_revenue) AS avg_monthly_revenue
    FROM analytics.subscriptions
    GROUP BY plan
),

plan_lifespan AS (
    SELECT
        plan,
        AVG(
            EXTRACT(YEAR FROM AGE(churn_date, signup_date)) * 12
            + EXTRACT(MONTH FROM AGE(churn_date, signup_date))
            + EXTRACT(DAY FROM AGE(churn_date, signup_date)) / 30.0
        ) AS avg_lifespan_months
    FROM analytics.subscriptions
    WHERE is_churned = TRUE
      AND churn_date IS NOT NULL
    GROUP BY plan
),

company_cac AS (
    SELECT
        AVG(customer_acquisition_cost) AS avg_cac
    FROM analytics.monthly_revenue
),

unit_economics AS (
    SELECT
        r.plan,
        r.avg_monthly_revenue * l.avg_lifespan_months AS estimated_clv,
        c.avg_cac
    FROM plan_revenue r
    JOIN plan_lifespan l
        ON r.plan = l.plan
    CROSS JOIN company_cac c
)

SELECT
    plan,
    ROUND(estimated_clv, 2) AS estimated_clv,
    ROUND(avg_cac, 2) AS avg_company_cac,

    ROUND(
        estimated_clv / NULLIF(avg_cac, 0),
        2
    ) AS clv_to_cac_ratio,

    RANK() OVER (
        ORDER BY estimated_clv / NULLIF(avg_cac, 0) DESC
    ) AS unit_economics_rank

FROM unit_economics

ORDER BY unit_economics_rank;

/*
===============================================================================
BQ5 OVERALL KEY FINDING
===============================================================================

- Customer lifetime value differs substantially across subscription plans.

- Enterprise has the highest estimated CLV at 44,042.21, followed by
  Business at 19,104.86, Professional at 5,315.95, and Starter at 1,452.64.

- Higher-tier plans also have longer observed customer lifespans.
  Enterprise and Business customers remain for approximately 14.75 and
  14.66 months respectively, compared with only 6.74 months for Starter.

- The company-wide average Customer Acquisition Cost (CAC) is 200.04.
  When estimated CLV is compared with this benchmark, Enterprise has the
  strongest CLV-to-CAC ratio at 220.17, followed by Business at 95.50,
  Professional at 26.57, and Starter at 7.26.

- Enterprise therefore has the strongest unit economics based on the
  available data, while Starter has the weakest.


===============================================================================
BUSINESS IMPACT
===============================================================================

- Enterprise customers are especially valuable because they combine high
  monthly revenue with longer customer relationships. Losing an Enterprise
  customer therefore puts substantially more lifetime revenue at risk.

- Business customers also represent significant long-term value and are an
  important segment to retain.

- Starter has the largest customer base but generates the lowest estimated
  lifetime value per customer. Combined with its previously identified high
  churn rate and short customer lifespan, this indicates an important
  opportunity to improve the value of the Starter customer base.

- The business should therefore consider two different retention priorities:
  protect high-value Enterprise and Business customers, while investigating
  ways to improve retention and customer lifetime among Starter customers.

- Plan performance should not be evaluated only by the number of customers.
  Customer lifespan, recurring revenue, churn, and acquisition cost should
  also be considered when evaluating the economic value of each plan.

*/