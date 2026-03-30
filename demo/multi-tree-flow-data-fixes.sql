-- =============================================================
-- MULTI-TREE FLOW DATA FIXES
-- Purpose: Keep each demo branch driven by clean, isolated data
-- Mutation path: Denodo writable views under the verticals database
-- =============================================================

-- =============================================================
-- WHY THIS PATCH EXISTS
--
-- We want the workflow behavior to come from the data, not from
-- branch-specific hard-coded prompt logic.
--
-- That means:
-- 1. Robert Logan (10117) should remain the dedicated new-loan
--    negative customer.
-- 2. Jane Doe (20000) should become an explicit servicing-negative
--    customer in the data itself.
-- 3. Compliance-negative should use its own dedicated customer,
--    instead of overloading Robert and breaking the underwriting flow.
-- =============================================================

-- =============================================================
-- SECTION 0: OPTIONAL CLEANUP
-- Run this only if the earlier Robert-based compliance patch was
-- already applied in your environment.
-- =============================================================

-- Restore Robert Logan to the original underwriting-negative scenario.
UPDATE verticals.financial_customers
SET income_band = 'Mid-High'
WHERE customer_id = 10117
  AND income_band = 'Low';

UPDATE verticals.financial_underwriting
SET financial_history = 'Poor'
WHERE underwriting_id = 2001
  AND financial_history = 'Collections history with derogatory items under review';

UPDATE verticals.financial_loans
SET status = 'approved'
WHERE loan_id = 7581
  AND status = 'active';

-- Remove the extra Robert compliance artifacts if they were inserted.
DELETE FROM verticals.customer_complaints
WHERE complaint_id = 4034
  AND customer_id = 10117;

DELETE FROM verticals.officer_transcripts
WHERE transcript_id = 2216
  AND customer_id = 10117;

DELETE FROM verticals.financial_loans
WHERE loan_id = 20002
  AND customer_id = 10117;

-- =============================================================
-- SECTION 1: Make Jane Doe an explicit servicing-negative case
-- =============================================================

-- The servicing workflow already understands a defaulted/default-like
-- loan as an escalation case. We make that signal explicit in the data.
--
-- If your underlying source has a status check constraint that does not
-- yet allow 'defaulted', extend it there first. The workflow should rely
-- on the data status rather than inferred special-case logic.
UPDATE verticals.financial_loans
SET status = 'defaulted'
WHERE loan_id = 20001
  AND customer_id = 20000;

-- =============================================================
-- SECTION 2: Add a dedicated compliance-negative customer
-- =============================================================

-- New customer chosen so compliance-negative no longer interferes with
-- Robert's new-loan negative path.
--
-- IDs chosen above the current observed max values from the MCP audit.

INSERT INTO verticals.financial_customers (
  customer_id,
  first_name,
  last_name,
  email,
  phone_number,
  address,
  city,
  state,
  zip_code,
  country,
  sex,
  loyalty_classification,
  risk_weighting,
  income_band,
  dob
) VALUES (
  21001,
  'Daniel',
  'Mercer',
  'daniel.mercer@example.com',
  '555-210-0001',
  '88 Harbor View Drive',
  'Miami',
  'FL',
  '33131',
  'US',
  'Male',
  'Platinum',
  9,
  'Low',
  '1986-04-11'
);

-- Two active loans create the overlapping-obligation signal the AML/KYC
-- branch can reason about. Reuse existing property records so we do not
-- need extra property inserts for the demo.
INSERT INTO verticals.financial_loans (
  loan_id,
  customer_id,
  loan_amount,
  interest_rate,
  term,
  property_id,
  loan_officer_id,
  status,
  date_created
) VALUES (
  21001,
  21001,
  425000.00,
  7.15,
  30,
  17390,
  1001,
  'active',
  '2026-02-14'
);

INSERT INTO verticals.financial_loans (
  loan_id,
  customer_id,
  loan_amount,
  interest_rate,
  term,
  property_id,
  loan_officer_id,
  status,
  date_created
) VALUES (
  21002,
  21001,
  185000.00,
  6.95,
  15,
  9700,
  1001,
  'active',
  '2026-03-03'
);

INSERT INTO verticals.customer_complaints (
  complaint_id,
  customer_id,
  complaint_text,
  channel,
  complaint_date,
  resolved,
  embedding
) VALUES (
  4101,
  21001,
  'Customer objected to repeated source-of-funds verification after attempting to route several large incoming transfers through newly linked external accounts. Customer stated they may split future transfers across multiple accounts if compliance continues to ask for documentation.',
  'call',
  '2026-03-27',
  false,
  embed_ai('Customer objected to repeated source-of-funds verification after attempting to route several large incoming transfers through newly linked external accounts. Customer stated they may split future transfers across multiple accounts if compliance continues to ask for documentation.')
);

INSERT INTO verticals.officer_transcripts (
  transcript_id,
  loan_officer_id,
  customer_id,
  transcript_text,
  meeting_date,
  meeting_type,
  embedding
) VALUES (
  2301,
  1001,
  21001,
  'Branch visit with Daniel Mercer. Customer challenged recent compliance questions about multiple external funding sources, could not clearly document the origin of funds, and suggested future transfers could be broken into smaller amounts to avoid review. Officer documented the behavior as suspicious and escalated the case for AML review.',
  '2026-03-29',
  'branch_visit',
  embed_ai('Branch visit with Daniel Mercer. Customer challenged recent compliance questions about multiple external funding sources, could not clearly document the origin of funds, and suggested future transfers could be broken into smaller amounts to avoid review. Officer documented the behavior as suspicious and escalated the case for AML review.')
);

-- =============================================================
-- VERIFICATION QUERIES
-- =============================================================

-- 1. Robert Logan should remain the dedicated new-loan negative case.
SELECT customer_id, first_name, last_name, income_band, risk_weighting
FROM verticals.financial_customers
WHERE customer_id = 10117;

SELECT loan_id, status, loan_amount, interest_rate, term
FROM verticals.financial_loans
WHERE customer_id = 10117
ORDER BY loan_id;

SELECT underwriting_id, loan_id, credit_score, employment_history, financial_history
FROM verticals.financial_underwriting
WHERE loan_id = 7581;

-- 2. Jane Doe should now be an explicit servicing-negative case.
SELECT loan_id, status, loan_amount, interest_rate, term
FROM verticals.financial_loans
WHERE customer_id = 20000
ORDER BY loan_id;

SELECT COUNT(*) AS payment_count
FROM verticals.financial_payments
WHERE loan_id = 20001;

-- 3. Daniel Mercer should now be the dedicated compliance-negative case.
SELECT customer_id, first_name, last_name, loyalty_classification, risk_weighting, income_band
FROM verticals.financial_customers
WHERE customer_id = 21001;

SELECT loan_id, status, loan_amount, interest_rate, term, property_id, date_created
FROM verticals.financial_loans
WHERE customer_id = 21001
ORDER BY loan_id;

SELECT complaint_id, complaint_date, channel, resolved, complaint_text
FROM verticals.customer_complaints
WHERE customer_id = 21001
ORDER BY complaint_id DESC;

SELECT transcript_id, meeting_date, meeting_type, transcript_text
FROM verticals.officer_transcripts
WHERE customer_id = 21001
ORDER BY transcript_id DESC;

-- =============================================================
-- TEST PROMPTS
-- =============================================================

-- new_loan positive
--   Analyze customer 18926 for loan eligibility
--
-- new_loan negative
--   Analyze customer 10117 for loan eligibility
--
-- existing_loan positive
--   Check payment status for customer 18926
--
-- existing_loan negative
--   Check payment status for customer 20000
--
-- compliance positive
--   Run AML review for customer 10033
--
-- compliance negative
--   Run AML review for customer 21001
