-- This is an example using PostgreSQL

-- These tables only need to be created once.
--- For each payment, run both queries in the same transaction.
--- Pass payment_id ($1) and order_id ($2) as params
--- instead of adding values directly to the SQL.

-- Before saving a payment, the backend should verify that the
--- notification came from Cashfree and the payment was successful..
---- It should also check the order ID, amount, and currency
--- against the original order details stored in the db.

CREATE TABLE payment_receipts (
  payment_id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL
);

CREATE TABLE fulfillment_outbox (
  order_id TEXT PRIMARY KEY NOT NULL,
  processed_at TIMESTAMPTZ
);

BEGIN;

-- Save the payment only if it hasn't been recorded alreadyy
INSERT INTO payment_receipts (payment_id, order_id)
VALUES ($1, $2)
ON CONFLICT (payment_id) DO NOTHING;

-- Add the enrollment request only if the payment belongs
--- to this order and an enrollment request doesn't already exist
INSERT INTO fulfillment_outbox (order_id)
SELECT $2
WHERE EXISTS (
  SELECT 1 FROM payment_receipts
  WHERE payment_id = $1 AND order_id = $2
)
ON CONFLICT (order_id) DO NOTHING;
COMMIT;
-- If a query fails, the backend should ROLLBACK instead of COMMIT