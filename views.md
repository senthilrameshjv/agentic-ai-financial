# Financial Services

**Folder:** `/financial services/banking/3 - Data Products`

---

## 1. customer_complaints

**Description:** Customer complaint records with semantic search capability.

| Column            | Type                         | Description |
|------------------|------------------------------|-------------|
| complaint_id     | long                         | Primary key; unique identifier |
| customer_id      | long                         | ID of the customer |
| complaint_text   | text                         | Full text of the complaint |
| channel          | text                         | Submission channel |
| complaint_date   | localdate                    | Date filed |
| resolved         | boolean                      | Resolution status |
| embedding        | vector<float, 1536>          | Vector for similarity search using `text-embedding-3-small` |

---

## 2. officer_transcripts

**Description:** Loan officer meeting transcripts with semantic search.

| Column            | Type                | Description |
|------------------|---------------------|-------------|
| transcript_id    | long                | Primary key; unique identifier |
| loan_officer_id  | long                | ID of the officer |
| customer_id      | long                | ID of the customer |
| transcript_text  | text                | Transcript content |
| meeting_date     | localdate           | Date of meeting |
| meeting_type     | text                | Category of meeting |
| embedding        | vector<float, 1536> | Vector for similarity search |

---

## 3. financial_customers

**Description:** Detailed customer profiles and financial classifications.

| Column                    | Type      | Description |
|---------------------------|-----------|-------------|
| customer_id              | long      | Unique customer identifier |
| first_name / last_name   | text      | Personal names |
| email / phone_number     | text      | Contact details |
| address / city / state / zip_code / country | text | Physical location |
| sex                      | text      | Gender |
| loyalty_classification   | text      | Engagement level/tier |
| risk_weighting           | long      | Perceived risk value |
| income_band              | text      | Income level category |
| dob                      | localdate | Date of birth |

---

## 4. financial_acct

**Description:** Overview of financial accounts and statuses.

| Column         | Type      | Description |
|----------------|-----------|-------------|
| acct_id        | long      | Unique account identifier |
| customer_id    | long      | Associated customer |
| acct_type      | text      | e.g., savings, checking |
| balance        | double    | Current monetary balance |
| date_created   | localdate | Date established |

---

## 5. financial_loans

**Description:** Comprehensive loan issuance and performance data.

| Column           | Type      | Description |
|------------------|-----------|-------------|
| loan_id          | long      | Unique loan identifier |
| customer_id      | long      | Associated borrower |
| loan_amount      | double    | Total principal borrowed |
| interest_rate    | double    | Percentage charged |
| term             | long      | Duration of loan |
| property_id      | long      | Financed property identifier |
| loan_officer_id  | long      | Responsible officer |
| status           | text      | e.g., active, paid, defaulted |
| date_created     | localdate | Record creation date |

---

## 6. financial_loanofficers

**Description:** Information on loan officer professionals.

| Column                 | Type | Description |
|------------------------|------|-------------|
| loan_officer_id        | long | Unique officer identifier |
| first_name / last_name | text | Professional identity |
| email / phone_number   | text | Contact information |

---

## 7. financial_payments

**Description:** Tracking of payment transactions associated with loans.

| Column          | Type   | Description |
|------------------|--------|-------------|
| payment_id       | long   | Unique transaction identifier |
| loan_id          | long   | Associated loan identifier |
| payment_amount   | double | Amount paid |
| payment_date     | text   | Date processed |

---

## 8. financial_properties

**Description:** Real estate property data and market values.

| Column                              | Type   | Description |
|-------------------------------------|--------|-------------|
| property_id                         | long   | Unique property identifier |
| address / city / state / zip_code   | text   | Property location |
| property_value                      | double | Assessed market value |

---

## 9. financial_rates

**Description:** Lending rates catalog for various loan types.

| Column         | Type   | Description |
|----------------|--------|-------------|
| rate_id        | long   | Unique rate record identifier |
| loan_type      | text   | e.g., personal, auto, mortgage |
| term           | long   | Duration of repayment |
| interest_rate  | double | Percentage charged |

---

## 10. financial_underwriting

**Description:** Risk assessments and creditworthiness data.

| Column              | Type   | Description |
|---------------------|--------|-------------|
| underwriting_id     | long   | Unique assessment identifier |
| loan_id             | long   | Associated loan application |
| credit_score        | long   | Financial reliability score |
| employment_history  | text   | Work history details |
| financial_history   | text   | Past financial behaviors |

---

## Key Relationships (Joins)

- **Customer Links:**  
  `customer_id` connects:
  - `financial_customers`
  - `financial_acct`
  - `financial_loans`
  - `customer_complaints`
  - `officer_transcripts`

- **Loan Links:**  
  `loan_id` connects:
  - `financial_loans`
  - `financial_payments`
  - `financial_underwriting`

- **Officer Links:**  
  `loan_officer_id` connects:
  - `financial_loanofficers`
  - `financial_loans`
  - `officer_transcripts`

- **Property Links:**  
  `property_id` connects:
  - `financial_loans`
  - `financial_properties`