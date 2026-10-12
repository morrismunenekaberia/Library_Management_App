/**
 * db/reset.js – Drops and recreates all database tables, then runs schema,
 * baseline seed, and demo seed data.
 *
 * Safety: REFUSES to run when NODE_ENV=production.
 * Usage: npm run db:reset
 */

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

// Safety guard: refuse to run when NODE_ENV=production
if (process.env.NODE_ENV === 'production') {
  console.error('❌  Error: Refusing to reset database in production environment (NODE_ENV=production).');
  process.exit(1);
}

// Load environment configuration
require('../src/config/env');
const pool = require('../src/config/database');
const { seedDemo } = require('./demo');

const SALT_ROUNDS = 10;

async function reset() {
  const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';

  console.log('🔄  Starting database reset...');

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Run schema (drops and recreates all tables)
    const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await client.query(schema);
    console.log('✔  Schema created (tables dropped and recreated)');

    // 2. Run baseline seed
    const seed = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
    await client.query(seed);
    console.log('✔  Baseline seed applied');

    // 3. Create admin (librarian) account
    const adminHash = await bcrypt.hash(adminPassword, SALT_ROUNDS);
    await client.query(
      `INSERT INTO users (username, password_hash, role)
       VALUES ($1, $2, 'librarian')
       ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash`,
      ['admin', adminHash]
    );
    console.log('✔  Admin librarian user created (username: admin)');

    // 4. Run demo seed (25 books across 5 categories, 10 active members + accounts, 8 loans)
    const stats = await seedDemo(client);
    console.log('✔  Demo seed applied:');
    console.log(`   - ${stats.books} books across 5 categories`);
    console.log(`   - ${stats.activeMembers} active members`);
    console.log(`   - ${stats.memberUsers} member user accounts (Password: ${stats.demoPassword})`);
    console.log(`   - ${stats.totalLoans} loans (${stats.activeLoans} active, ${stats.overdueLoans} overdue, ${stats.returnedLoans} returned)`);

    await client.query('COMMIT');
    console.log('\n✅  Database reset completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌  Database reset failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

reset();

