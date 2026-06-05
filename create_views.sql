CREATE OR REPLACE VIEW v_active_fraud_alerts AS
SELECT
    f.alert_id,
    f.risk_score,
    f.created_at,
    t.amount,
    t.merchant_country,
    c.first_name,
    c.last_name,
    c.email

FROM fraud_alerts f
INNER JOIN transactions t ON f.transaction_id = t.transaction_id
INNER JOIN accounts a ON t.account_id = a.account_id
INNER JOIN customers c ON a.customer_id = c.customer_id
WHERE f.alert_status = 'OPEN';


CREATE OR REPLACE VIEW v_country_risk_transactions AS
SELECT
    t.transaction_id,
    t.amount,
    t.merchant_country,
    t.status,
    t.risk_score,
    t.transaction_at,
    c.first_name,
    c.last_name,
    c.email

FROM transactions t
INNER JOIN accounts a ON t.account_id = a.account_id
INNER JOIN customers c ON a.customer_id = c.customer_id
WHERE is_high_risk_country(t.merchant_country) = TRUE;


CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS
SELECT
    DATE(t.transaction_at) AS transaction_date,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_amount,
    COUNT(t.transaction_id) FILTER (WHERE t.status = 'FLAGGED') AS flagged_count,
    SUM(t.amount) FILTER (WHERE t.status = 'FLAGGED') AS suspicious_amount,
    AVG(t.risk_score) AS avg_risk_score,
    COUNT(f.alert_id) AS total_alerts

FROM transactions t
LEFT JOIN fraud_alerts  f ON f.transaction_id = t.transaction_id
GROUP BY DATE(t.transaction_at)
ORDER BY transaction_date DESC;


CREATE MATERIALIZED VIEW mv_customer_risk_summary AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(t.transaction_id) AS transactions_count,
    COUNT(t.transaction_id) FILTER (WHERE t.status = 'FLAGGED') AS flagged_count,
    AVG(t.risk_score) AS avg_risk_score,
    COUNT(f.alert_id) AS total_alerts,
    SUM(t.amount) AS total_amount

FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
LEFT JOIN fraud_alerts f ON f.transaction_id = t.transaction_id
GROUP BY c.customer_id


