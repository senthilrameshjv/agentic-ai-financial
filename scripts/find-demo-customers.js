import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';

const MCP_URL = 'http://localhost:8080/verticals/mcp';
const AUTH = 'Basic YWRtaW46YWRtaW4=';

async function sql(client, query) {
  const result = await client.callTool({ name: 'denodo_verticals_run_sql_query', arguments: { sql_query: query } });
  const text = result.content?.[0]?.text;
  try { return JSON.parse(text)?.data ?? []; } catch { return []; }
}

async function main() {
  const transport = new StreamableHTTPClientTransport(new URL(MCP_URL), {
    requestInit: { headers: { Authorization: AUTH } }
  });
  const client = new Client({ name: 'demo-finder', version: '1.0.0' });
  await client.connect(transport);
  console.log('Connected to Denodo MCP\n');

  // Get current market rates once
  const rates = await sql(client, 'SELECT loan_type, term, interest_rate FROM financial_rates');

  function getMarketRate(loanType, term) {
    const match = rates.find(r =>
      r.loan_type?.toLowerCase() === loanType?.toLowerCase() &&
      Number(r.term) === Number(term)
    );
    return match ? Number(match.interest_rate) : null;
  }

  // Get 20 customers that have at least one approved loan (joined)
  const candidates = await sql(client, `
    SELECT DISTINCT c.customer_id, c.first_name, c.last_name,
           c.risk_weighting, c.income_band, c.loyalty_classification, c.dob
    FROM financial_loans l
    JOIN financial_customers c ON l.customer_id = c.customer_id
    WHERE l.status = 'approved'
    LIMIT 20
  `);
  console.log(`Found ${candidates.length} customers with approved loans. Evaluating...\n`);

  const results = [];

  for (const cust of candidates) {
    const id = cust.customer_id;
    const name = `${cust.first_name} ${cust.last_name}`;
    process.stdout.write(`Checking ${id} (${name})... `);

    // All loans for this customer
    const loans = await sql(client, `SELECT * FROM financial_loans WHERE customer_id = ${id}`);
    const approvedLoans = loans.filter(l => l.status === 'approved');

    // Payments across all approved loans
    let totalPayments = 0;
    let missedPaymentFlag = false;
    for (const loan of approvedLoans) {
      const payments = await sql(client,
        `SELECT payment_amount, payment_date FROM financial_payments WHERE loan_id = ${loan.loan_id} ORDER BY payment_date DESC`
      );
      totalPayments += payments.length;
      // Flag if fewer than 3 payments on an approved loan (possible delinquency)
      if (payments.length < 3) missedPaymentFlag = true;
    }

    // Credit score from underwriting (first loan)
    let creditScore = null;
    if (loans.length > 0) {
      const uw = await sql(client,
        `SELECT credit_score FROM financial_underwriting WHERE loan_id = ${loans[0].loan_id}`
      );
      if (uw.length) creditScore = Number(uw[0].credit_score);
    }

    // Best refinancing gap across approved loans
    let refiGap = 0;
    for (const loan of approvedLoans) {
      const marketRate = getMarketRate(loan.loan_type, loan.term);
      if (marketRate !== null) {
        const gap = Number(loan.interest_rate) - marketRate;
        if (gap > refiGap) refiGap = gap;
      }
    }

    // Complaints
    const complaints = await sql(client,
      `SELECT complaint_id, complaint_text, resolved FROM customer_complaints WHERE customer_id = ${id}`
    );

    // Transcripts
    const transcripts = await sql(client,
      `SELECT transcript_id, meeting_type, meeting_date FROM officer_transcripts WHERE customer_id = ${id} ORDER BY meeting_date DESC`
    );

    // Scoring
    const riskWeighting = Number(cust.risk_weighting);
    const highRisk = riskWeighting > 7;
    const lowCredit = creditScore !== null && creditScore < 620;
    const hasRefi = refiGap > 1.0;

    const score2 = (missedPaymentFlag ? 2 : 0) + (lowCredit ? 2 : 0) + (highRisk ? 1 : 0);
    const score3 = score2
      + (complaints.length > 0 ? 2 : 0)
      + (transcripts.length > 0 ? 2 : 0)
      + (hasRefi ? 3 : 0)
      + (approvedLoans.length > 0 ? 1 : 0);

    console.log(
      `loans=${loans.length}(approved=${approvedLoans.length}) ` +
      `credit=${creditScore ?? '?'} risk=${riskWeighting} ` +
      `pmts=${totalPayments} refi=${refiGap.toFixed(2)}% ` +
      `complaints=${complaints.length} transcripts=${transcripts.length} | S2=${score2} S3=${score3}`
    );

    results.push({
      id, name, cust, loans, approvedLoans,
      totalPayments, missedPaymentFlag,
      creditScore, riskWeighting, highRisk, lowCredit,
      refiGap, hasRefi, complaints, transcripts,
      score2, score3
    });
  }

  // --- Rankings ---
  console.log('\n========================================');
  console.log('SCORING SUMMARY (sorted by S3 score)');
  console.log('========================================');
  console.log('ID       Name                      S2  S3  Risk  Credit  Approved  Pmts  Complaints  Transcripts  RefiGap%');
  console.log('-------  ------------------------  --  --  ----  ------  --------  ----  ----------  -----------  --------');
  for (const r of [...results].sort((a, b) => b.score3 - a.score3)) {
    console.log(
      String(r.id).padEnd(8),
      r.name.padEnd(25),
      String(r.score2).padEnd(3),
      String(r.score3).padEnd(3),
      String(r.riskWeighting).padEnd(5),
      String(r.creditScore ?? '?').padEnd(7),
      String(r.approvedLoans.length).padEnd(9),
      String(r.totalPayments).padEnd(5),
      String(r.complaints.length).padEnd(11),
      String(r.transcripts.length).padEnd(12),
      r.refiGap.toFixed(2)
    );
  }

  // --- Recommendations ---
  const sorted2 = [...results].sort((a, b) => b.score2 - a.score2);
  const sorted3 = [...results].sort((a, b) => b.score3 - a.score3);
  const best1 = results.find(r => r.approvedLoans.length > 0);
  const best2 = sorted2[0];
  const best3 = sorted3[0];

  console.log('\n========================================');
  console.log('RECOMMENDED DEMO CUSTOMERS');
  console.log('========================================');

  console.log('\n--- SCENARIO 1: Basic Profile Lookup ---');
  if (best1) {
    const loan = best1.approvedLoans[0];
    console.log(`Customer: ${best1.name} (ID: ${best1.id})`);
    console.log(`  Income: ${best1.cust.income_band} | Loyalty: ${best1.cust.loyalty_classification} | Risk: ${best1.riskWeighting}`);
    console.log(`  Approved loan: $${loan?.loan_amount?.toFixed(2)} @ ${loan?.interest_rate}%`);
    console.log(`  Demo question: "Find customer ${best1.name} and show me their profile and account balances."`);
  }

  console.log('\n--- SCENARIO 2: Default Risk Analysis ---');
  if (best2) {
    console.log(`Customer: ${best2.name} (ID: ${best2.id})`);
    console.log(`  Risk signals: S2=${best2.score2} | Risk weighting: ${best2.riskWeighting} (>7: ${best2.highRisk}) | Credit: ${best2.creditScore ?? '?'} (<620: ${best2.lowCredit}) | Low payments: ${best2.missedPaymentFlag}`);
    console.log(`  Demo question: "Is ${best2.cust.first_name} at risk of defaulting on any of their loans?"`);
  }

  console.log('\n--- SCENARIO 3: Full Pre-Meeting Briefing ---');
  if (best3) {
    console.log(`Customer: ${best3.name} (ID: ${best3.id})`);
    console.log(`  S3=${best3.score3} | Risk: ${best3.riskWeighting} | Credit: ${best3.creditScore ?? '?'} | Refi gap: ${best3.refiGap.toFixed(2)}%`);
    console.log(`  Complaints: ${best3.complaints.length} | Transcripts: ${best3.transcripts.length}`);
    if (best3.complaints.length) console.log(`  Sample complaint: "${best3.complaints[0].complaint_text?.slice(0, 120)}"`);
    if (best3.transcripts.length) console.log(`  Latest transcript: ${best3.transcripts[0].meeting_type} on ${best3.transcripts[0].meeting_date}`);
    console.log(`  Demo question: "Prepare a full pre-meeting briefing for my meeting with ${best3.name} tomorrow."`);
  }

  await client.close();
}

main().catch(err => { console.error('Error:', err.message ?? err); process.exit(1); });
