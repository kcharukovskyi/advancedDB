CREATE OR REPLACE FUNCTION is_high_risk_country(p_country_code VARCHAR(3))
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p_country_code IN ('RUS', 'BLR', 'PRK', 'IRN', 'SYR', 'MMR', 'YEM', 'SDN', 'LBY', 'MLI', 'BFA', 'CYM', 'VGB', 'PAN', 'LIE', 'MCO', 'SMR', 'AND');
END;
$$;


CREATE OR REPLACE FUNCTION get_customer_age(p_customer_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE customer_age INTEGER;

BEGIN
    SELECT
        CAST(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS INTEGER) -- Claude was asked how should I retype float value to integer
    INTO customer_age
    FROM customers
    WHERE customer_id = p_customer_id;
    RETURN customer_age;
END;
$$;


CREATE OR REPLACE FUNCTION calculate_customer_daily_volume(p_customer_id UUID, p_date DATE)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE customer_daily_volume DECIMAL;

BEGIN
    SELECT COALESCE(SUM(t.amount), 0)
    INTO customer_daily_volume
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE a.customer_id = p_customer_id
    AND DATE(t.transaction_at) = p_date
    AND t.status != 'DECLINED';
    RETURN customer_daily_volume;
END;
$$;



CREATE OR REPLACE FUNCTION calculate_transaction_risk_score(p_transaction_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    risk_score INTEGER := 0;
    amount DECIMAL;
    country VARCHAR(3);
    transaction_time TIMESTAMP;
    cust_id UUID;
    daily_count INTEGER;
    daily_volume DECIMAL;

BEGIN
    SELECT t.amount, t.merchant_country, t.transaction_at, a.customer_id
    INTO amount, country, transaction_time, cust_id
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE t.transaction_id = p_transaction_id;

    SELECT COUNT(*)
    INTO daily_count
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE a.customer_id = cust_id
    AND DATE(t.transaction_at) = DATE(transaction_time);

    daily_volume := calculate_customer_daily_volume(cust_id, DATE(transaction_time));

    IF amount >= 400000 THEN risk_score := risk_score + 40; END IF;
    IF daily_count > 15 THEN risk_score := risk_score + 30; END IF;
    IF daily_volume > 50000 THEN risk_score := risk_score + 30; END IF;
    IF is_high_risk_country(country) THEN risk_score := risk_score + 35; END IF;
    IF EXTRACT(HOUR FROM transaction_time) BETWEEN 2 AND 5 THEN risk_score := risk_score + 20; END IF;

    RETURN risk_score;
END;
$$;


SELECT current_database();



