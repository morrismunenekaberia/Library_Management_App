/**
 * db/init.js – Initializes the database.
 *
 * 1. Runs schema.sql  (creates / recreates all tables)
 * 2. Runs seed.sql    (inserts sample members and books)
 * 3. Hashes ADMIN_PASSWORD from env and inserts the librarian user
 *
 * Usage:  npm run db:init
 */

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

// Load env vars before importing the pool
require('../src/config/env');
const pool = require('../src/config/database');

const SALT_ROUNDS = 10;

async function run() {
  const adminPassword = process.env.ADMIN_PASSWORD;
  if (!adminPassword) {
    console.error('Error: ADMIN_PASSWORD environment variable is required.');
    process.exit(1);
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Run schema
    const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await client.query(schema);
    console.log('✔  Schema created');

    // 2. Run seed
    const seed = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
    await client.query(seed);
    console.log('✔  Seed data inserted (3 members, 5 books)');

    // 3. Create admin user with hashed password
    const hash = await bcrypt.hash(adminPassword, SALT_ROUNDS);
    await client.query(
      `INSERT INTO users (username, password_hash, role)
       VALUES ($1, $2, 'librarian')`,
      ['admin', hash]
    );
    console.log('✔  Admin user created (username: admin)');

    await client.query('COMMIT');
    console.log('\nDatabase initialised successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Database initialisation failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();

