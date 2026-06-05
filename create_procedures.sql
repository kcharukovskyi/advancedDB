CREATE OR REPLACE PROCEDURE create_fraud_alert(p_transaction_id UUID, p_reason TEXT, p_risk_score INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fraud_alerts (transaction_id, reason, risk_score)
    VALUES (p_transaction_id, p_reason, p_risk_score);
END;
$$;


CREATE OR REPLACE PROCEDURE process_transaction(p_transaction_id UUID)
LANGUAGE plpgsql
AS $$
DECLARE
    score INTEGER;
    new_status transaction_status_enum;
BEGIN
    score := calculate_transaction_risk_score(p_transaction_id);

    IF score >= 60 THEN
        new_status := 'FLAGGED';
    ELSIF score >= 30 THEN
        new_status := 'PENDING';
    ELSE
        new_status := 'APPROVED';
    END IF;

    UPDATE transactions
    SET risk_score = score, status = new_status
    WHERE transaction_id = p_transaction_id;

    IF new_status = 'FLAGGED' THEN
        CALL create_fraud_alert(p_transaction_id, 'High risk score', score);
    END IF;

END;
$$;


CREATE OR REPLACE PROCEDURE freeze_account(p_account_id UUID)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE accounts
    SET status = 'FROZEN'
    WHERE account_id = p_account_id;
END;
$$;



