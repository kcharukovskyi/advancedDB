-- Cron daily scheduling for both MVs with start at 1 AM.

CREATE EXTENSION IF NOT EXISTS pg_cron;


SELECT cron.schedule(
    'refresh_fraud_views',
    '0 1 * * *',
    $$
    REFRESH MATERIALIZED VIEW mv_daily_fraud_summary;
    REFRESH MATERIALIZED VIEW mv_customer_risk_summary;
    $$
);

SELECT * FROM cron.job;