# Banking Fraud Monitoring System


---

## Project Overview

This project implements a production-like fraud detection database system for a fictional Ukrainian bank. The system stores customer, account, card, and transaction data, and automatically detects suspicious activity using a rule-based risk scoring engine built in PostgreSQL.

The core idea: every transaction inserted into the database is automatically evaluated by a chain of triggers, functions, and stored procedures — no application-layer code needed. If a transaction is flagged as suspicious, a fraud alert is created instantly.

---

## Files

| File | Description |
|------|-------------|
| `create_tables.sql` | ENUMs, table definitions, constraints |
| `create_functions.sql` | Risk scoring, country validation, helper functions |
| `create_procedures.sql` | Business logic: process transaction, freeze account, create alert |
| `create_triggers.sql` | Automation: fraud detection on insert, status history, customer protection |
| `create_views.sql` | Analytical views and materialized views |
| `create_cron.sql` | Scheduled materialized view refresh via pg_cron |
| `insert_data.sql` | Sample data generation (1000+ transactions) |
| `example_queries.sql` | Demo analytical queries |

---

## Setup Instructions

### Prerequisites

- PostgreSQL 18
- pg_cron extension

### Installation

1. Create the database:
```sql
CREATE DATABASE fraud_monitoring;
```

2. Connect to the database and run scripts in this exact order:
```bash
psql -U postgres -d fraud_monitoring -f create_tables.sql
psql -U postgres -d fraud_monitoring -f create_functions.sql
psql -U postgres -d fraud_monitoring -f create_procedures.sql
psql -U postgres -d fraud_monitoring -f create_triggers.sql
psql -U postgres -d fraud_monitoring -f create_views.sql
psql -U postgres -d fraud_monitoring -f insert_data.sql
psql -U postgres -d fraud_monitoring -f create_cron.sql
```

3. Refresh materialized views after data load:
```sql
REFRESH MATERIALIZED VIEW mv_daily_fraud_summary;
REFRESH MATERIALIZED VIEW mv_customer_risk_summary;
```

### Order matters
Scripts must be run sequentially due to dependencies: types ->  tables -> functions -> procedures -> triggers.

---

## Assumptions

- All amounts are stored in the account's native currency -- no currency conversion is performed.
- A transaction can exist without a card (e.g. bank transfer via account number).
- Transactions and fraud alerts are never physically deleted — historical integrity is enforced via `ON DELETE RESTRICT`.
- Deleting a customer with active accounts is blocked at the database level.
- Risk scoring thresholds are based on Ukrainian AML legislation and NBU Regulation.

---

## Fraud Detection Logic

The system uses a **cumulative risk score**. Each transaction is evaluated against five rules immediately after insertion. Points are summed and the transaction receives a final status.

### Risk Rules

| Rule | Condition | Points |
|------|-----------|--------|
| HIGH_AMOUNT | Transaction ≥ 400,000 UAH (NBU threshold) | +40 |
| HIGH_RISK_COUNTRY | Merchant country on FATF/aggressor list | +35 |
| DAILY_VOLUME | Customer daily spend > 50,000 UAH | +25 |
| NIGHT_TRANSACTION | Transaction between 02:00–05:00 | +20 |
| DAILY_VELOCITY | > 15 transactions in 24 hours | +30 |

### Status Assignment

| Score | Status |
|-------|--------|
| 0–29 | `APPROVED` |
| 30–59 | `PENDING` — requires review |
| 60+ | `FLAGGED` — fraud alert created automatically |

### High-Risk Countries

The system flags transactions from countries on the FATF blacklist/greylist, Ukrainian-designated aggressor states, and common offshore jurisdictions:

- **Aggressor states**: Russia (RUS), Belarus (BLR)
- **FATF**: Iran (IRN), North Korea (PRK), Syria (SYR), Myanmar (MMR), Yemen (YEM), Sudan (SDN), Libya (LBY)
- **Offshore**: Cayman Islands (CYM), BVI (VGB), Panama (PAN), Liechtenstein (LIE)

---

## Automated Processing Pipeline

When a transaction is inserted, the following chain executes automatically:

```
INSERT INTO transactions
    → trigger_new_transaction (AFTER INSERT)
        → CALL process_transaction()
            → calculate_transaction_risk_score()
                → is_high_risk_country()
                → calculate_customer_daily_volume()
            → UPDATE transactions SET status, risk_score
            → IF FLAGGED → CALL create_fraud_alert()
    → trigger_status_change (AFTER UPDATE)
        → INSERT INTO transaction_status_history
```

---

## Materialized View Refresh Strategy

Two materialized views provide analytical dashboards:

- `mv_daily_fraud_summary` — daily fraud statistics
- `mv_customer_risk_summary` — per-customer risk aggregates

Both are refreshed automatically every day at **01:00** via `pg_cron`
---

## AI Tools Usage

Claude was used for:
- Syntax assistance on PL/pgSQL functions and trigger definitions
- Sample data generation scripts (`insert_data.sql`)
- README.md drafting

All business logic, fraud rules, and architectural decisions were designed independently, informed by Ukrainian AML legislation research (with LLM research support).
