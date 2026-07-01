const mysql = require('mysql2');
require('dotenv').config();

// Create MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  port: process.env.DB_PORT || 15157,
  database: process.env.DB_NAME || 'raahi_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Cloud databases usually require SSL. 
  // This turns SSL on if you aren't on localhost.
  ssl: process.env.DB_HOST !== 'localhost' ? { rejectUnauthorized: false } : false
});

// Convert pool to use promises
const promisePool = pool.promise();

// Test database connection with better error handling
promisePool.getConnection()
  .then(connection => {
    console.log('✅ Connected to MySQL database');
    connection.release();
  })
  .catch(err => {
    console.error('❌ Database connection failed:');
    console.error('   Error:', err.message);
    console.error('   Check your MySQL server is running');
    console.error('   Check database credentials in .env file');
    console.error('   Make sure database "raahi_db" exists');
  });

module.exports = promisePool;