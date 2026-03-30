import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';

const MCP_URL = 'http://localhost:8080/verticals/mcp';
const AUTH = 'Basic YWRtaW46YWRtaW4=';

async function sql(client, query) {
  const result = await client.callTool({
    name: 'denodo_verticals_run_sql_query',
    arguments: { sql_query: query },
  });
  const text = result.content?.[0]?.text;
  try {
    return JSON.parse(text)?.data ?? [];
  } catch {
    return { raw: text };
  }
}

async function fetchCustomerBundle(client, customerId) {
  const customer = await sql(
    client,
    `SELECT customer_id, first_name, last_name, loyalty_classification, risk_weighting, income_band
     FROM financial_customers
     WHERE customer_id = ${customerId}`,
  );

  const loans = await sql(
    client,
    `SELECT loan_id, status, loan_amount, interest_rate, term, property_id
     FROM financial_loans
     WHERE customer_id = ${customerId}
     ORDER BY loan_id`,
  );

  const complaints = await sql(
    client,
    `SELECT complaint_id
     FROM customer_complaints
     WHERE customer_id = ${customerId}`,
  );

  const transcripts = await sql(
    client,
    `SELECT transcript_id
     FROM officer_transcripts
     WHERE customer_id = ${customerId}`,
  );

  const enrichedLoans = [];
  for (const loan of Array.isArray(loans) ? loans : []) {
    const underwriting = await sql(
      client,
      `SELECT underwriting_id, credit_score, employment_history, financial_history
       FROM financial_underwriting
       WHERE loan_id = ${loan.loan_id}`,
    );

    const property = await sql(
      client,
      `SELECT property_id, property_value
       FROM financial_properties
       WHERE property_id = ${loan.property_id}`,
    );

    const payments = await sql(
      client,
      `SELECT payment_id, payment_amount, payment_date
       FROM financial_payments
       WHERE loan_id = ${loan.loan_id}`,
    );

    enrichedLoans.push({
      ...loan,
      underwriting: Array.isArray(underwriting) ? underwriting[0] ?? null : underwriting,
      property: Array.isArray(property) ? property[0] ?? null : property,
      payment_count: Array.isArray(payments) ? payments.length : 0,
    });
  }

  return {
    customer: Array.isArray(customer) ? customer[0] ?? null : customer,
    loans: enrichedLoans,
    complaint_count: Array.isArray(complaints) ? complaints.length : 0,
    transcript_count: Array.isArray(transcripts) ? transcripts.length : 0,
  };
}

function formatBundle(label, bundle) {
  return {
    label,
    customer: bundle.customer,
    complaint_count: bundle.complaint_count,
    transcript_count: bundle.transcript_count,
    loans: bundle.loans.map((loan) => ({
      loan_id: loan.loan_id,
      status: loan.status,
      loan_amount: loan.loan_amount,
      interest_rate: loan.interest_rate,
      term: loan.term,
      property_id: loan.property_id,
      property_value: loan.property?.property_value ?? null,
      credit_score: loan.underwriting?.credit_score ?? null,
      financial_history: loan.underwriting?.financial_history ?? null,
      payment_count: loan.payment_count,
    })),
  };
}

async function main() {
  const transport = new StreamableHTTPClientTransport(new URL(MCP_URL), {
    requestInit: { headers: { Authorization: AUTH } },
  });
  const client = new Client({ name: 'multi-tree-flow-audit', version: '1.0.0' });
  await client.connect(transport);

  const probes = [
    { label: 'new_loan_positive_candidate', customerId: 18926 },
    { label: 'new_loan_negative_candidate', customerId: 10117 },
    { label: 'existing_negative_candidate', customerId: 20000 },
    { label: 'compliance_positive_candidate', customerId: 10033 },
    { label: 'compliance_negative_candidate', customerId: 10117 },
  ];

  const output = {};
  for (const probe of probes) {
    const bundle = await fetchCustomerBundle(client, probe.customerId);
    output[probe.label] = formatBundle(probe.label, bundle);
  }

  output.dataset_summary = {
    loan_statuses: await sql(
      client,
      'SELECT status, COUNT(*) AS cnt FROM financial_loans GROUP BY status ORDER BY cnt DESC',
    ),
    rates: await sql(
      client,
      'SELECT rate_id, loan_type, term, interest_rate FROM financial_rates ORDER BY loan_type, term, interest_rate',
    ),
    max_ids: await sql(
      client,
      `SELECT
         (SELECT MAX(customer_id) FROM financial_customers) AS max_customer_id,
         (SELECT MAX(loan_id) FROM financial_loans) AS max_loan_id,
         (SELECT MAX(underwriting_id) FROM financial_underwriting) AS max_underwriting_id,
         (SELECT MAX(payment_id) FROM financial_payments) AS max_payment_id,
         (SELECT MAX(complaint_id) FROM customer_complaints) AS max_complaint_id,
         (SELECT MAX(transcript_id) FROM officer_transcripts) AS max_transcript_id,
         (SELECT MAX(rate_id) FROM financial_rates) AS max_rate_id`,
    ),
  };

  console.log(JSON.stringify(output, null, 2));
  await client.close();
}

main().catch((error) => {
  console.error(error?.message ?? error);
  process.exit(1);
});
