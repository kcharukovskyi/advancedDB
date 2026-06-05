SELECT * FROM mv_customer_risk_summary
ORDER BY total_alerts DESC LIMIT 5;

SELECT * FROM v_active_fraud_alerts;

SELECT * FROM v_country_risk_transactions;

SELECT * FROM transaction_status_history LIMIT 10;


SELECT
    DATE(DATE_TRUNC('week', transaction_at)) AS week,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE status = 'FLAGGED') AS flagged,
    ROUND(COUNT(*) FILTER (WHERE status = 'FLAGGED') * 100.0 / COUNT(*)) AS fraud_rate_pct
FROM transactions
GROUP BY week
ORDER BY week DESC;


SELECT
    c.first_name,
    c.last_name,
    c.email,
    COUNT(*) AS risky_transactions_count,
    SUM(t.amount) AS total_risky_amount

FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
JOIN transactions t ON t.account_id = a.account_id
WHERE is_high_risk_country(t.merchant_country)
GROUP BY c.customer_id
ORDER BY risky_transactions_count DESC
LIMIT 10;
