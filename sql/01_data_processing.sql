/*==============================================================================
    Project: SaaS Revenue & Customer Churn Analysis
    Load, profile, validate, and prepare the raw SaaS datasets for analysis
    Database: PostgreSQL

    Source datasets:
    1. subscriptions.csv
    2. monthly_revenue.csv

    Processing approach:
    Raw CSV -> Raw Tables -> Data Profiling -> Data Quality Validation
            -> Analytics-Ready Tables -> Final Validation

    - Raw tables are preserved unchanged after import.
    - Cleaning/transformation is only performed when analytically justified.

--CREATE PROJECT SCHEMAS

-- Keep source data and processed analytical data logically separated.
*/

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================================================
--  CREATE RAW TABLES
-- ============================================================================

DROP TABLE IF EXISTS raw.subscriptions;

DROP TABLE IF EXISTS raw.monthly_revenue;

CREATE TABLE raw.monthly_revenue (
    month                       VARCHAR(7),
    total_active_customers      INTEGER,
    new_customers               INTEGER,
    churned_customers           INTEGER,
    monthly_churn_rate_pct      NUMERIC(6,2),
    total_mrr                   NUMERIC(14,2),
    avg_revenue_per_customer    NUMERIC(12,2),
    customer_acquisition_cost   NUMERIC(12,2)
);

CREATE TABLE raw.subscriptions (
    customer_id             VARCHAR(20),
    plan                    VARCHAR(50),
    billing_cycle           VARCHAR(20),
    industry                VARCHAR(100),
    company_size            VARCHAR(20),
    seats                   INTEGER,
    monthly_revenue         NUMERIC(12,2),
    acquisition_channel     VARCHAR(50),
    region                  VARCHAR(50),
    signup_date             DATE,
    churned                 VARCHAR(10),
    churn_date              DATE,
    churn_reason            VARCHAR(100),
    support_tickets_12mo    INTEGER,
    nps_score               INTEGER,
    feature_usage_pct       INTEGER,
    upgraded                VARCHAR(10)
);
-- ============================================================================
--  VERIFY DATA LOADING
-- ============================================================================

SELECT
    COUNT(*) AS subscription_rows
FROM raw.subscriptions;


SELECT
    COUNT(*) AS monthly_revenue_rows
FROM raw.monthly_revenue;

SELECT * FROM raw.monthly_revenue;
SELECT * FROM raw.subscriptions;

-- ============================================================================
--  DATASET STRUCTURE & COVERAGE
-- ============================================================================
SELECT
    MIN(signup_date) AS earliest_signup_date,
    MAX(signup_date) AS latest_signup_date,
    MIN(churn_date) AS earliest_churn_date,
    MAX(churn_date) AS latest_churn_date
FROM raw.subscriptions;

-- Monthly revenue coverage

SELECT
    MIN(TO_DATE(month, 'YYYY-MM')) AS first_month,
    MAX(TO_DATE(month, 'YYYY-MM')) AS last_month,
    COUNT(DISTINCT month) AS months_available
FROM raw.monthly_revenue;


-- ============================================================================
-- NULL VALUE ASSESSMENT — SUBSCRIPTIONS
-- ============================================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS customer_id_nulls,

    COUNT(*) FILTER (
        WHERE plan IS NULL
    ) AS plan_nulls,

    COUNT(*) FILTER (
        WHERE billing_cycle IS NULL
    ) AS billing_cycle_nulls,

    COUNT(*) FILTER (
        WHERE industry IS NULL
    ) AS industry_nulls,

    COUNT(*) FILTER (
        WHERE company_size IS NULL
    ) AS company_size_nulls,

    COUNT(*) FILTER (
        WHERE seats IS NULL
    ) AS seats_nulls,

    COUNT(*) FILTER (
        WHERE monthly_revenue IS NULL
    ) AS monthly_revenue_nulls,

    COUNT(*) FILTER (
        WHERE acquisition_channel IS NULL
    ) AS acquisition_channel_nulls,

    COUNT(*) FILTER (
        WHERE region IS NULL
    ) AS region_nulls,

    COUNT(*) FILTER (
        WHERE signup_date IS NULL
    ) AS signup_date_nulls,

    COUNT(*) FILTER (
        WHERE churned IS NULL
    ) AS churned_nulls,

    COUNT(*) FILTER (
        WHERE churn_date IS NULL
    ) AS churn_date_nulls,

    COUNT(*) FILTER (
        WHERE churn_reason IS NULL
    ) AS churn_reason_nulls,

    COUNT(*) FILTER (
        WHERE support_tickets_12mo IS NULL
    ) AS support_tickets_nulls,

    COUNT(*) FILTER (
        WHERE nps_score IS NULL
    ) AS nps_score_nulls,

    COUNT(*) FILTER (
        WHERE feature_usage_pct IS NULL
    ) AS feature_usage_nulls,

    COUNT(*) FILTER (
        WHERE upgraded IS NULL
    ) AS upgraded_nulls

FROM raw.subscriptions;


/*
Expected from source inspection:

churn_date   = 287 NULL
churn_reason = 287 NULL

These NULL values belong to customers who have NOT churned.

They represent valid business meaning and must NOT automatically be filled,
deleted, or treated as data-quality errors.
*/

- ============================================================================
-- VALIDATE CHURN-RELATED NULLS
-- ============================================================================

SELECT
    churned,
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE churn_date IS NULL
    ) AS missing_churn_date,

    COUNT(*) FILTER (
        WHERE churn_reason IS NULL
    ) AS missing_churn_reason

FROM raw.subscriptions
GROUP BY churned
ORDER BY churned;

/*
Expected:

churned = Yes
    churn_date populated
    churn_reason populated

churned = No
    churn_date NULL
    churn_reason NULL

	Churn-related null values were validated against customer churn status.
	All 287 non-churned customers had null churn dates and reasons, 
	while all 313 churned customers contained complete churn information, 
	confirming that these nulls represent valid business states rather than data-quality issues.
*/


-- --------------------------------------------------------------------------
-- Detect logically inconsistent churn records
-- --------------------------------------------------------------------------

SELECT *
FROM raw.subscriptions

WHERE
       (churned = 'Yes' AND churn_date IS NULL)

    OR (churned = 'Yes' AND churn_reason IS NULL)

    OR (churned = 'No' AND churn_date IS NOT NULL)

    OR (churned = 'No' AND churn_reason IS NOT NULL);


/*
Expected:

0 rows

If records are returned, investigate them before continuing.
*/
-- ============================================================================
-- 10. NULL VALUE ASSESSMENT — MONTHLY REVENUE
-- ============================================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE month IS NULL
    ) AS month_nulls,

    COUNT(*) FILTER (
        WHERE total_active_customers IS NULL
    ) AS active_customer_nulls,

    COUNT(*) FILTER (
        WHERE new_customers IS NULL
    ) AS new_customer_nulls,

    COUNT(*) FILTER (
        WHERE churned_customers IS NULL
    ) AS churned_customer_nulls,

    COUNT(*) FILTER (
        WHERE monthly_churn_rate_pct IS NULL
    ) AS churn_rate_nulls,

    COUNT(*) FILTER (
        WHERE total_mrr IS NULL
    ) AS total_mrr_nulls,

    COUNT(*) FILTER (
        WHERE avg_revenue_per_customer IS NULL
    ) AS arpc_nulls,

    COUNT(*) FILTER (
        WHERE customer_acquisition_cost IS NULL
    ) AS cac_nulls

FROM raw.monthly_revenue;


/*
Expected:

No NULL values.
*/

-- ============================================================================
--  DUPLICATE CHECKS
-- ============================================================================


-- --------------------------------------------------------------------------
-- Duplicate customer IDs
-- --------------------------------------------------------------------------

SELECT
    customer_id,
    COUNT(*) AS occurrence_count

FROM raw.subscriptions

GROUP BY customer_id

HAVING COUNT(*) > 1;


/*
Expected:

0 rows

customer_id should uniquely identify each customer.
*/


-- Fully duplicated subscription records
-- --------------------------------------------------------------------------

SELECT
    customer_id,
    plan,
    billing_cycle,
    industry,
    company_size,
    seats,
    monthly_revenue,
    acquisition_channel,
    region,
    signup_date,
    churned,
    churn_date,
    churn_reason,
    support_tickets_12mo,
    nps_score,
    feature_usage_pct,
    upgraded,
    COUNT(*) AS duplicate_count

FROM raw.subscriptions

GROUP BY
    customer_id,
    plan,
    billing_cycle,
    industry,
    company_size,
    seats,
    monthly_revenue,
    acquisition_channel,
    region,
    signup_date,
    churned,
    churn_date,
    churn_reason,
    support_tickets_12mo,
    nps_score,
    feature_usage_pct,
    upgraded

HAVING COUNT(*) > 1;


/*
Expected:

0 rows
*/

-- Duplicate months
-- --------------------------------------------------------------------------

SELECT
    month,
    COUNT(*) AS occurrence_count

FROM raw.monthly_revenue

GROUP BY month

HAVING COUNT(*) > 1;


/*
Expected:

0 rows

Each month should occur once.
*/

-- ============================================================================
-- CATEGORICAL VALUE PROFILING
-- ============================================================================


-- --------------------------------------------------------------------------
-- Subscription plans
-- --------------------------------------------------------------------------

SELECT
    plan,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY plan

ORDER BY customers DESC;


/*
Expected:

Starter
Professional
Business
Enterprise
*/


-- --------------------------------------------------------------------------
-- Billing cycles
-- --------------------------------------------------------------------------

SELECT
    billing_cycle,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY billing_cycle

ORDER BY customers DESC;


/*
Expected:

Monthly
Annual
*/


-- --------------------------------------------------------------------------
-- Company sizes
-- --------------------------------------------------------------------------

SELECT
    company_size,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY company_size

ORDER BY customers DESC;


/*
Expected:

1-10
11-50
51-200
201-500
500+
*/


-- --------------------------------------------------------------------------
-- Acquisition channels
-- --------------------------------------------------------------------------

SELECT
    acquisition_channel,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY acquisition_channel

ORDER BY customers DESC;


-- --------------------------------------------------------------------------
-- Regions
-- --------------------------------------------------------------------------

SELECT
    region,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY region

ORDER BY customers DESC;


-- --------------------------------------------------------------------------
-- Churn status
-- --------------------------------------------------------------------------

SELECT
    churned,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY churned

ORDER BY churned;


/*
Expected from source inspection:

Yes = 313
No  = 287
*/


-- --------------------------------------------------------------------------
-- Upgrade status
-- --------------------------------------------------------------------------

SELECT
    upgraded,
    COUNT(*) AS customers

FROM raw.subscriptions

GROUP BY upgraded

ORDER BY upgraded;


-- --------------------------------------------------------------------------
-- Churn reasons
-- --------------------------------------------------------------------------

SELECT
    churn_reason,
    COUNT(*) AS churned_customers

FROM raw.subscriptions

WHERE churn_reason IS NOT NULL

GROUP BY churn_reason

ORDER BY churned_customers DESC;

-- ============================================================================
-- NUMERIC RANGE PROFILING
-- ============================================================================

SELECT
    MIN(seats) AS min_seats,
    MAX(seats) AS max_seats,

    MIN(monthly_revenue) AS min_monthly_revenue,
    MAX(monthly_revenue) AS max_monthly_revenue,

    MIN(support_tickets_12mo) AS min_support_tickets,
    MAX(support_tickets_12mo) AS max_support_tickets,

    MIN(nps_score) AS min_nps_score,
    MAX(nps_score) AS max_nps_score,

    MIN(feature_usage_pct) AS min_feature_usage_pct,
    MAX(feature_usage_pct) AS max_feature_usage_pct

FROM raw.subscriptions;


/*
Observed source ranges:

seats                1 → 297
monthly_revenue      24.65 → 10,978.00
support tickets      0 → 15
NPS score            1 → 10
feature usage        10 → 95
*/

-- ============================================================================
--  DATE LOGIC VALIDATION
-- ============================================================================

-- A customer cannot churn before signing up.

SELECT *
FROM raw.subscriptions

WHERE
    churn_date IS NOT NULL
    AND churn_date < signup_date;


/*
Expected:

0 rows
*/


-- ============================================================================
-- MONTHLY REVENUE CONSISTENCY CHECK
-- ============================================================================

/*
Business rule:

ARPC ≈ Total MRR / Active Customers

This check determines whether the provided ARPC field is internally
consistent with the other monthly metrics.

NULLIF prevents division by zero.
*/

SELECT
    month,
    total_active_customers,
    total_mrr,
    avg_revenue_per_customer,

    ROUND(
        total_mrr
        / NULLIF(total_active_customers, 0),
        2
    ) AS calculated_arpc,

    ROUND(
        avg_revenue_per_customer
        -
        (
            total_mrr
            / NULLIF(total_active_customers, 0)
        ),
        2
    ) AS arpc_difference

FROM raw.monthly_revenue

ORDER BY month;


/*==============================================================================
  DATA CLEANING DECISION
==============================================================================*/

/*
After profiling and validation:

- No duplicate customer IDs were identified.
- No fully duplicated records were identified.
- No duplicate monthly periods were identified.
- Numeric values fall within valid ranges.
- Churn dates do not precede signup dates.
- Churn-related NULLs are structurally valid.
- Categories are already consistently represented.

The original values remain preserved in the raw schema.
*/

-- ============================================================================
-- CREATE ANALYTICS-READY SUBSCRIPTIONS TABLE
-- ============================================================================

DROP TABLE IF EXISTS analytics.subscriptions;


CREATE TABLE analytics.subscriptions AS

SELECT
    customer_id,
    plan,
    billing_cycle,
    industry,
    company_size,
    seats,
    monthly_revenue,
    acquisition_channel,
    region,
    signup_date,

    CASE
        WHEN churned = 'Yes' THEN TRUE
        WHEN churned = 'No'  THEN FALSE
    END AS is_churned,

    churn_date,
    churn_reason,
    support_tickets_12mo,
    nps_score,
    feature_usage_pct,

    CASE
        WHEN upgraded = 'Yes' THEN TRUE
        WHEN upgraded = 'No'  THEN FALSE
    END AS is_upgraded

FROM raw.subscriptions;


/*------------------------------------------------------------------------------
 WHY CONVERT TO BOOLEAN?

 churned and upgraded represent binary business states.

Boolean fields make later SQL easier and clearer:

WHERE is_churned

instead of:

WHERE churned = 'Yes'
------------------------------------------------------------------------------*/


-- ============================================================================
-- ADD DATA INTEGRITY CONSTRAINTS — SUBSCRIPTIONS
-- ============================================================================

ALTER TABLE analytics.subscriptions
ADD CONSTRAINT pk_subscriptions
PRIMARY KEY (customer_id);


ALTER TABLE analytics.subscriptions
ADD CONSTRAINT chk_positive_seats
CHECK (seats > 0);


ALTER TABLE analytics.subscriptions
ADD CONSTRAINT chk_nonnegative_monthly_revenue
CHECK (monthly_revenue >= 0);


ALTER TABLE analytics.subscriptions
ADD CONSTRAINT chk_support_tickets
CHECK (support_tickets_12mo >= 0);


ALTER TABLE analytics.subscriptions
ADD CONSTRAINT chk_nps_score
CHECK (nps_score BETWEEN 1 AND 10);


ALTER TABLE analytics.subscriptions
ADD CONSTRAINT chk_feature_usage
CHECK (feature_usage_pct BETWEEN 0 AND 100);


ALTER TABLE analytics.subscriptions
ADD CONSTRAINT chk_churn_date
CHECK (
    churn_date IS NULL
    OR churn_date >= signup_date
);


-- ============================================================================
-- CREATE ANALYTICS-READY MONTHLY REVENUE TABLE
-- ============================================================================

DROP TABLE IF EXISTS analytics.monthly_revenue;


CREATE TABLE analytics.monthly_revenue AS

SELECT
    TO_DATE(month, 'YYYY-MM') AS month,
    total_active_customers,
    new_customers,
    churned_customers,
    monthly_churn_rate_pct,
    total_mrr,
    avg_revenue_per_customer,
    customer_acquisition_cost

FROM raw.monthly_revenue;


/*
Transformation:

Raw:

2022-01

Analytics:

2022-01-01

PostgreSQL stores this as DATE.

This allows:

DATE_TRUNC()
EXTRACT()
LAG()
LEAD()
period comparisons
time-series analysis
*/


-- ============================================================================
-- ADD DATA INTEGRITY CONSTRAINTS — MONTHLY REVENUE
-- ============================================================================

ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT pk_monthly_revenue
PRIMARY KEY (month);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_active_customers
CHECK (total_active_customers >= 0);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_new_customers
CHECK (new_customers >= 0);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_churned_customers
CHECK (churned_customers >= 0);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_monthly_churn_rate
CHECK (
    monthly_churn_rate_pct BETWEEN 0 AND 100
);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_total_mrr
CHECK (total_mrr >= 0);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_arpc
CHECK (avg_revenue_per_customer >= 0);


ALTER TABLE analytics.monthly_revenue
ADD CONSTRAINT chk_cac
CHECK (customer_acquisition_cost >= 0);


-- ============================================================================
-- FINAL ROW-COUNT VALIDATION
-- ============================================================================

SELECT
    (SELECT COUNT(*)
     FROM raw.subscriptions)
        AS raw_subscription_rows,

    (SELECT COUNT(*)
     FROM analytics.subscriptions)
        AS analytics_subscription_rows,

    (SELECT COUNT(*)
     FROM raw.monthly_revenue)
        AS raw_monthly_rows,

    (SELECT COUNT(*)
     FROM analytics.monthly_revenue)
        AS analytics_monthly_rows;


/*
Expected:

raw_subscription_rows       = 600
analytics_subscription_rows = 600

raw_monthly_rows             = 48
analytics_monthly_rows       = 48

The transformation should not remove any valid records.
*/


-- ============================================================================
-- FINAL CHURN VALIDATION
-- ============================================================================

SELECT
    is_churned,
    COUNT(*) AS customers

FROM analytics.subscriptions

GROUP BY is_churned

ORDER BY is_churned DESC;


/*
Expected:

TRUE  = 313
FALSE = 287
*/


-- --------------------------------------------------------------------------
-- Check churn consistency after transformation
-- --------------------------------------------------------------------------

SELECT *
FROM analytics.subscriptions

WHERE
       (
           is_churned = TRUE
           AND (
               churn_date IS NULL
               OR churn_reason IS NULL
           )
       )

    OR (
           is_churned = FALSE
           AND (
               churn_date IS NOT NULL
               OR churn_reason IS NOT NULL
           )
       );


/*
Expected:

0 rows
*/


-- ============================================================================
-- FINAL MONTHLY DATA VALIDATION
-- ============================================================================

SELECT
    MIN(month) AS first_month,
    MAX(month) AS last_month,
    COUNT(*) AS total_months

FROM analytics.monthly_revenue;


/*
Expected:

first_month  = 2022-01-01
last_month   = 2025-12-01
total_months = 48
*/


-- ============================================================================
-- PREVIEW ANALYTICS-READY DATA
-- ============================================================================

SELECT *
FROM analytics.subscriptions
ORDER BY customer_id
LIMIT 10;


SELECT *
FROM analytics.monthly_revenue
ORDER BY month
LIMIT 10;


/*==============================================================================
 DATA PROCESSING COMPLETE
==============================================================================*/

/*
FINAL OUTPUT

raw.subscriptions
        ↓
analytics.subscriptions

raw.monthly_revenue
        ↓
analytics.monthly_revenue


The analytics tables are now ready for:


Exploratory Data Analysis:

- Customer composition
- Subscription composition
- Revenue distribution
- Customer engagement
- Churn patterns
- Customer lifecycle
- MRR trends
- ARPC trends
- CAC trends
- Potential anomalies
*/

/*==============================================================================
 END OF 01_data_processing.sql
==============================================================================*/
