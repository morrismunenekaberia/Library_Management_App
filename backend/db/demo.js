/**
 * db/demo.js – Seeds demo data for testing and presentations.
 *
 * 1. Runs demo-seed.sql (25 books across 5 categories, 10 active members, 8 loans)
 * 2. Hashes the demo member password with bcrypt and creates linked user accounts
 * 3. Re-synchronizes available_copies on all books
 *
 * Safe to re-run (idempotent; no duplicates, no failures).
 * Usage: npm run db:demo
 */

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

// Load environment configuration
require('../src/config/env');
const pool = require('../src/config/database');

const SALT_ROUNDS = 10;
const DEMO_PASSWORD = process.env.DEMO_MEMBER_PASSWORD || 'Member123!';

/**
 * Executes the demo seeding within an active DB client / transaction.
 * @param {import('pg').PoolClient} client
 */
async function seedDemo(client) {
  // 1. Run demo SQL file (books, members, loans, available_copies sync)
  const sql = fs.readFileSync(path.join(__dirname, 'demo-seed.sql'), 'utf8');
  await client.query(sql);

  // 2. Fetch all members and create / update linked user accounts
  const membersRes = await client.query(
    'SELECT id, admission_number FROM members ORDER BY id ASC'
  );

  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, SALT_ROUNDS);

  for (const member of membersRes.rows) {
    await client.query(
      `INSERT INTO users (username, password_hash, role, member_id)
       VALUES ($1, $2, 'member', $3)
       ON CONFLICT (username) DO UPDATE SET
         password_hash = EXCLUDED.password_hash,
         role = 'member',
         member_id = EXCLUDED.member_id`,
      [member.admission_number, passwordHash, member.id]
    );
  }

  // 3. Verification query
  const statsRes = await client.query(`
    SELECT
      (SELECT COUNT(*)::int FROM books) AS books,
      (SELECT COUNT(*)::int FROM members WHERE status = 'active') AS active_members,
      (SELECT COUNT(*)::int FROM users WHERE role = 'member') AS member_users,
      (SELECT COUNT(*)::int FROM loans) AS total_loans,
      (SELECT COUNT(*)::int FROM loans WHERE returned_at IS NULL AND due_date >= NOW()) AS active_loans,
      (SELECT COUNT(*)::int FROM loans WHERE returned_at IS NULL AND due_date < NOW()) AS overdue_loans,
      (SELECT COUNT(*)::int FROM loans WHERE returned_at IS NOT NULL) AS returned_loans
  `);
  const row = statsRes.rows[0];

  return {
    books: row.books,
    activeMembers: row.active_members,
    memberUsers: row.member_users,
    totalLoans: row.total_loans,
    activeLoans: row.active_loans,
    overdueLoans: row.overdue_loans,
    returnedLoans: row.returned_loans,
    demoPassword: DEMO_PASSWORD,
  };
}

async function run() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const stats = await seedDemo(client);
    await client.query('COMMIT');

    console.log('✔  Demo data seeded successfully:');
    console.log(`   - Books: ${stats.books} across 5 categories`);
    console.log(`   - Members: ${stats.activeMembers} active members`);
    console.log(`   - Member User Accounts: ${stats.memberUsers} accounts (Password: ${stats.demoPassword})`);
    console.log(`   - Loans: ${stats.totalLoans} total (${stats.activeLoans} active, ${stats.overdueLoans} overdue, ${stats.returnedLoans} returned)`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Demo data seeding failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  run();
}

module.exports = { seedDemo };
