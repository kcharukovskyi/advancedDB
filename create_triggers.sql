    -- Used Claude for syntax and logic a lot here, must admit. For some suspicious reason I'm highly confused with triggers.

    CREATE OR REPLACE FUNCTION func_trigger_new_transaction()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
        CALL process_transaction(NEW.transaction_id);
        RETURN NEW;
    END;
    $$;

    CREATE OR REPLACE TRIGGER trigger_new_transaction
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION func_trigger_new_transaction();


    CREATE OR REPLACE FUNCTION func_trigger_status_change()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF OLD.status != NEW.status THEN
            INSERT INTO transaction_status_history (transaction_id, old_status, new_status, changed_by)
            VALUES (NEW.transaction_id, OLD.status, NEW.status, 'system');
        END IF;
        RETURN NEW;
    END;
    $$;

    CREATE OR REPLACE TRIGGER trigger_status_change
    AFTER UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION func_trigger_status_change();


    CREATE OR REPLACE FUNCTION func_trigger_protect_customer()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF EXISTS (
            SELECT 1 FROM accounts
            WHERE customer_id = OLD.customer_id
            AND status = 'ACTIVE'
        ) THEN
            RAISE EXCEPTION 'Cannot delete customer (has active accounts)';
        END IF;
        RETURN OLD;
    END;
    $$;

    CREATE OR REPLACE TRIGGER trigger_protect_customer
    BEFORE DELETE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION func_trigger_protect_customer();


    CREATE OR REPLACE FUNCTION func_audit_insert()
    RETURNS TRIGGER LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO audit_log (customer_id, table_name, operation, old_value, new_value)
        VALUES (NEW.customer_id, 'customers', 'INSERT', NULL, row_to_json(NEW));
        RETURN NEW;
    END;
    $$;

    CREATE OR REPLACE TRIGGER trigger_audit_insert
    AFTER INSERT ON customers
    FOR EACH ROW EXECUTE FUNCTION func_audit_insert();


    CREATE OR REPLACE FUNCTION func_audit_delete()
    RETURNS TRIGGER LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO audit_log (customer_id, table_name, operation, old_value, new_value)
        VALUES (OLD.customer_id, 'customers', 'DELETE', row_to_json(OLD), NULL);
        RETURN OLD;
    END;
    $$;

    CREATE OR REPLACE TRIGGER trigger_audit_delete
    AFTER DELETE ON customers
    FOR EACH ROW EXECUTE FUNCTION func_audit_delete();


    CREATE OR REPLACE FUNCTION func_audit_update()
    RETURNS TRIGGER LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO audit_log (customer_id, table_name, operation, old_value, new_value)
        VALUES (NEW.customer_id, 'customers', 'UPDATE', row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    END;
    $$;

    CREATE OR REPLACE TRIGGER trigger_audit_update
    AFTER UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION func_audit_update();

