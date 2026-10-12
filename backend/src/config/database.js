const { Pool } = require('pg');
const env = require('./env');

// Single shared connection pool for the entire app
const pool = new Pool(env.db);

module.exports = pool;

