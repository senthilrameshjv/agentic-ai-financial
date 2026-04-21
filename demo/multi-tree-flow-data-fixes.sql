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
-- 1. Randy Spence (18926) should be a reliable positive customer for
--    both the new-loan happy path and the existing-loan positive path.
--    To make that deterministic with the current workflow, Randy must
--    present as a single-loan customer.
-- 2. Robert Logan (10117) should remain the dedicated new-loan
--    negative customer.
-- 3. Jane Doe (20000) should become an explicit servicing-negative
--    customer in the data itself and remain available for the
--    investigation/rate-retention storyline.
-- 4. Compliance-negative should use its own dedicated customer,
--    instead of overloading Robert and breaking the underwriting flow.
-- =============================================================

-- =============================================================
-- SECTION 0: IDEMPOTENT RESET
-- Safe to run on every execution. All mutations use conditional
-- WHERE clauses or DELETE-before-INSERT so repeated runs are
-- harmless.
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

-- Remove Daniel Mercer artifacts so this script can be rerun cleanly.
DELETE FROM verticals.officer_transcripts
WHERE transcript_id = 2301
  AND customer_id = 21001;

DELETE FROM verticals.customer_complaints
WHERE complaint_id = 4101
  AND customer_id = 21001;

DELETE FROM verticals.financial_loans
WHERE loan_id IN (21001, 21002)
  AND customer_id = 21001;

DELETE FROM verticals.financial_customers
WHERE customer_id = 21001;

-- Reset the neutral relocated-loan customer so Randy can be rebuilt
-- consistently on reruns.
UPDATE verticals.financial_loans
SET customer_id = 18926
WHERE loan_id = 13147
  AND customer_id = 21003;

DELETE FROM verticals.financial_customers
WHERE customer_id = 21003;

-- =============================================================
-- SECTION 1: Normalize Randy Spence as the positive underwriting case
-- =============================================================

-- Randy currently has two loans. One of them (loan_id = 336) is a
-- low-id pending loan with no underwriting row and an LTV > 100%.
-- We fixed that record, but the workflow still behaves poorly when a
-- customer has multiple loans because the agents can aggregate values
-- across both loans and then fail to bind a single property.
--
-- To keep the happy path deterministic using data alone:
-- - loan_id 336 becomes Randy's single canonical loan
-- - loan_id 13147 is reassigned to a neutral customer
--
-- This keeps:
-- - Analyze customer 18926 for loan eligibility -> positive flow
-- - Check payment status for customer 18926 -> positive flow

UPDATE verticals.financial_loans
SET status = 'approved',
    loan_amount = 465000.00,
    interest_rate = 3.75,
    term = 25
WHERE loan_id = 336
  AND customer_id = 18926;

DELETE FROM verticals.financial_underwriting
WHERE loan_id = 336;

INSERT INTO verticals.financial_underwriting (
  underwriting_id,
  loan_id,
  credit_score,
  employment_history,
  financial_history
) VALUES (
  2003,
  336,
  790,
  'Stable',
  'Excellent'
);

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
  21003,
  'Olivia',
  'Parker',
  'olivia.parker@example.com',
  '555-210-0003',
  '14 Cypress Lane',
  'Austin',
  'TX',
  '78701',
  'US',
  'Female',
  'Gold',
  4,
  'High',
  '1988-09-22'
);

UPDATE verticals.financial_loans
SET customer_id = 21003
WHERE loan_id = 13147
  AND customer_id = 18926;

-- =============================================================
-- SECTION 2: Recreate Jane Doe demo data from the original setup
-- =============================================================

-- multi-tree-flow-data-fixes.sql is the final demo setup script, so it
-- also needs the core Jane/Sarah/rates artifacts that originally lived
-- in data-setup.sql.

DELETE FROM verticals.officer_transcripts
WHERE transcript_id = 2215
  AND customer_id = 20000;

DELETE FROM verticals.customer_complaints
WHERE complaint_id = 4033
  AND customer_id = 20000;

DELETE FROM verticals.financial_underwriting
WHERE underwriting_id = 2002
   OR loan_id = 20001;

DELETE FROM verticals.financial_loans
WHERE loan_id = 20001
  AND customer_id = 20000;

DELETE FROM verticals.financial_customers
WHERE customer_id = 20000;

-- Remove and recreate Sarah so the transcript/loan fixtures are fully
-- defined by this final script.
DELETE FROM verticals.financial_loanofficers
WHERE loan_officer_id = 1001;

DELETE FROM verticals.financial_rates
WHERE rate_id = 6;

INSERT INTO verticals.financial_loanofficers (
  loan_officer_id,
  first_name,
  last_name,
  email,
  phone_number
) VALUES (
  1001,
  'Sarah',
  'Chen',
  'sarah.chen@bank.com',
  '555-200-1001'
);

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
  20000,
  'Jane',
  'Doe',
  'jane.doe@example.com',
  '555-867-5309',
  '1234 Oak Street',
  'San Francisco',
  'CA',
  '94105',
  'US',
  'Female',
  'Diamond',
  5,
  'High',
  '1978-06-15'
);

INSERT INTO verticals.financial_loans (
  loan_id,
  customer_id,
  loan_amount,
  interest_rate,
  term,
  status,
  property_id,
  loan_officer_id,
  date_created
) VALUES (
  20001,
  20000,
  500000.00,
  7.50,
  30,
  'active',
  1,
  1001,
  '2019-03-15'
);

INSERT INTO verticals.financial_underwriting (
  underwriting_id,
  loan_id,
  credit_score,
  employment_history,
  financial_history
) VALUES (
  2002,
  20001,
  810,
  'Stable',
  'Excellent - no missed payments in 7 years'
);

INSERT INTO verticals.customer_complaints (
  complaint_id,
  customer_id,
  complaint_text,
  complaint_date,
  channel,
  resolved,
  embedding
) VALUES (
  4033,
  20000,
  'My mortgage rate is way too high. I have been a loyal Diamond customer for six years with an excellent credit history and zero missed payments. Competitor B contacted me last week and offered 6.2% on a comparable 30-year fixed mortgage. My current rate of 7.50% is simply not competitive. I am seriously considering switching lenders unless we can match or beat that offer.',
  '2026-03-20',
  'call',
  false,
  embed_ai('My mortgage rate is way too high. I have been a loyal Diamond customer for six years with an excellent credit history and zero missed payments. Competitor B contacted me last week and offered 6.2% on a comparable 30-year fixed mortgage. My current rate of 7.50% is simply not competitive. I am seriously considering switching lenders unless we can match or beat that offer.')
);

INSERT INTO verticals.officer_transcripts (
  transcript_id,
  customer_id,
  loan_officer_id,
  meeting_date,
  meeting_type,
  transcript_text,
  embedding
) VALUES (
  2215,
  20000,
  1001,
  '2026-03-24',
  'branch_visit',
  'Customer Jane Doe visited the branch on March 24, 2026 for a scheduled meeting with Relationship Manager Sarah Chen. Customer expressed strong frustration with her current mortgage rate of 7.50% on a $500,000 30-year fixed mortgage originated in March 2019. She stated that Competitor B contacted her last week and offered a rate of 6.2% on a comparable 30-year fixed mortgage. Customer has maintained a flawless payment record for over 7 years and confirmed her credit score is 810. She has been a Diamond loyalty tier customer for six years and expressed disappointment that her long-standing relationship has not resulted in a preferential rate. Key quote: "I have been a Diamond customer for six years. I expect better. Competitor B called me last week with 6.2%. Match it or I am gone." RM Chen acknowledged the concern, confirmed she would escalate to the pricing team, and committed to responding with a formal rate offer within 24 hours. Customer defection risk assessed as high. Immediate follow-up action required.',
  embed_ai('Customer Jane Doe visited the branch on March 24, 2026 for a scheduled meeting with Relationship Manager Sarah Chen. Customer expressed strong frustration with her current mortgage rate of 7.50% on a $500,000 30-year fixed mortgage originated in March 2019. She stated that Competitor B contacted her last week and offered a rate of 6.2% on a comparable 30-year fixed mortgage. Customer has maintained a flawless payment record for over 7 years and confirmed her credit score is 810. She has been a Diamond loyalty tier customer for six years and expressed disappointment that her long-standing relationship has not resulted in a preferential rate. Key quote: "I have been a Diamond customer for six years. I expect better. Competitor B called me last week with 6.2%. Match it or I am gone." RM Chen acknowledged the concern, confirmed she would escalate to the pricing team, and committed to responding with a formal rate offer within 24 hours. Customer defection risk assessed as high. Immediate follow-up action required.')
);

INSERT INTO verticals.financial_rates (
  rate_id,
  loan_type,
  term,
  interest_rate
) VALUES (
  6,
  'Mortgage',
  30,
  6.00
);

-- =============================================================
-- SECTION 3: Make Jane Doe an explicit servicing-negative case
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
-- SECTION 4: Add a dedicated compliance-negative customer
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
-- SECTION 5: Extend Randy Spence payment history to current date
-- =============================================================
--
-- The existing 51 payment records for loan 336 run April 2024 –
-- April 2025. From the current date (2026) the agent sees a 12-month
-- trailing gap and interprets it as delinquency, triggering the Risk
-- Gate. This section adds 12 monthly on-time payments covering
-- May 2025 – April 2026 so the history reads as current.
--
-- Monthly payment for $465,000 at 3.75% over 25 years ≈ $2,391.
-- IDs start above the observed MAX(payment_id) of 1,000,000.
-- DELETE-before-INSERT keeps the section idempotent on reruns.

DELETE FROM verticals.financial_payments
WHERE loan_id = 336
  AND payment_id BETWEEN 1000001 AND 1000012;

INSERT INTO verticals.financial_payments (payment_id, loan_id, payment_amount, payment_date)
VALUES
  (1000001, 336, 2391.00, '2025-05-15'),
  (1000002, 336, 2391.00, '2025-06-15'),
  (1000003, 336, 2391.00, '2025-07-15'),
  (1000004, 336, 2391.00, '2025-08-15'),
  (1000005, 336, 2391.00, '2025-09-15'),
  (1000006, 336, 2391.00, '2025-10-15'),
  (1000007, 336, 2391.00, '2025-11-15'),
  (1000008, 336, 2391.00, '2025-12-15'),
  (1000009, 336, 2391.00, '2026-01-15'),
  (1000010, 336, 2391.00, '2026-02-15'),
  (1000011, 336, 2391.00, '2026-03-15'),
  (1000012, 336, 2391.00, '2026-04-15');

-- =============================================================
-- VERIFICATION QUERIES
-- =============================================================

-- 1. Randy Spence should now be the dedicated positive case.
SELECT customer_id, first_name, last_name, income_band, risk_weighting
FROM verticals.financial_customers
WHERE customer_id = 18926;

-- Randy payments: 63 total expected (51 original + 12 new), latest 2026-04-15.
SELECT COUNT(*) AS total_payments, MAX(payment_date) AS latest_payment
FROM verticals.financial_payments
WHERE loan_id = 336;

SELECT loan_id, status, loan_amount, interest_rate, term, property_id
FROM verticals.financial_loans
WHERE customer_id = 18926
ORDER BY loan_id;

SELECT underwriting_id, loan_id, credit_score, employment_history, financial_history
FROM verticals.financial_underwriting
WHERE loan_id IN (336, 13147)
ORDER BY loan_id;

SELECT property_id, property_value
FROM verticals.financial_properties
WHERE property_id = 19840
ORDER BY property_id;

SELECT customer_id, first_name, last_name, income_band, risk_weighting
FROM verticals.financial_customers
WHERE customer_id = 21003;

SELECT loan_id, status, loan_amount, interest_rate, term, property_id
FROM verticals.financial_loans
WHERE customer_id = 21003
ORDER BY loan_id;

-- 2. Robert Logan should remain the dedicated new-loan negative case.
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

-- 3. Jane Doe should now be an explicit servicing-negative case.
SELECT loan_officer_id, first_name, last_name, email
FROM verticals.financial_loanofficers
WHERE loan_officer_id = 1001;

SELECT customer_id, first_name, last_name, loyalty_classification, risk_weighting, income_band
FROM verticals.financial_customers
WHERE customer_id = 20000;

SELECT loan_id, status, loan_amount, interest_rate, term
FROM verticals.financial_loans
WHERE customer_id = 20000
ORDER BY loan_id;

SELECT underwriting_id, loan_id, credit_score, employment_history, financial_history
FROM verticals.financial_underwriting
WHERE loan_id = 20001;

SELECT COUNT(*) AS payment_count
FROM verticals.financial_payments
WHERE loan_id = 20001;

SELECT complaint_id, complaint_date, channel, resolved, complaint_text
FROM verticals.customer_complaints
WHERE customer_id = 20000
ORDER BY complaint_id DESC;

SELECT transcript_id, meeting_date, meeting_type, transcript_text
FROM verticals.officer_transcripts
WHERE customer_id = 20000
ORDER BY transcript_id DESC;

SELECT rate_id, loan_type, term, interest_rate
FROM verticals.financial_rates
WHERE rate_id = 6;

-- 4. Daniel Mercer should now be the dedicated compliance-negative case.
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
