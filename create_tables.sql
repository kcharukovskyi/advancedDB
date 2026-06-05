CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE transaction_status_enum AS ENUM ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED');
CREATE TYPE account_status_enum AS ENUM ('ACTIVE', 'FROZEN', 'CLOSED');
CREATE TYPE card_status_enum AS ENUM ('ACTIVE', 'BLOCKED', 'EXPIRED');
CREATE TYPE alert_status_enum AS ENUM ('OPEN', 'REVIEWED', 'CLOSED');
CREATE TYPE currency_enum AS ENUM ('UAH', 'USD', 'EUR');

CREATE TABLE customers (
    customer_id  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name   VARCHAR(255) NOT NULL,
    last_name    VARCHAR(255) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    birth_date   DATE,
    country_code VARCHAR(3),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active    BOOLEAN DEFAULT TRUE
);

CREATE TABLE accounts (
    account_id     UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id    UUID NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number VARCHAR(34) NOT NULL UNIQUE CHECK (account_number ~ '^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,30}$'),
    currency       currency_enum,
    balance        DECIMAL(15,2) DEFAULT 0 CHECK (balance >= 0),
    status         account_status_enum DEFAULT 'ACTIVE',
    opened_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cards (
    card_id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    account_id       UUID NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    card_number_hash VARCHAR(255) NOT NULL UNIQUE,
    card_type        VARCHAR(50),
    status           card_status_enum DEFAULT 'ACTIVE',
    expiration_date  DATE
);

CREATE TABLE fraud_rules (
    rule_id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    rule_name       VARCHAR(100) NOT NULL,
    rule_type       VARCHAR(50),
    threshold_value INT,
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE transactions (
    transaction_id    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    account_id        UUID NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    card_id           UUID REFERENCES cards(card_id) ON DELETE SET NULL,
    amount            DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency          currency_enum,
    merchant_category VARCHAR(100),
    merchant_country  VARCHAR(3),
    status            transaction_status_enum DEFAULT 'PENDING',
    risk_score        INT DEFAULT 0,
    transaction_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_status_history (
    history_id     UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id UUID NOT NULL REFERENCES transactions(transaction_id) ON DELETE RESTRICT,
    old_status     transaction_status_enum,
    new_status     transaction_status_enum,
    changed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by     VARCHAR(100)
);

CREATE TABLE fraud_alerts (
    alert_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id UUID NOT NULL REFERENCES transactions(transaction_id) ON DELETE RESTRICT ,
    rule_id        UUID REFERENCES fraud_rules(rule_id) ON DELETE SET NULL,
    reason         TEXT,
    risk_score     INT,
    alert_status   alert_status_enum DEFAULT 'OPEN',
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_log (
    audit_id    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES customers(customer_id) ON DELETE SET NULL,
    table_name  VARCHAR(100),
    operation   VARCHAR(10),
    old_value   JSON,
    new_value   JSON,
    changed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


SELECT current_database();