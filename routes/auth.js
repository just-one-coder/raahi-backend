const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const router = express.Router();

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'raahi_secret_key';

// Signup Route (MySQL)
router.post('/signup', async (req, res) => {
  const [result] = await pool.execute(
      `INSERT INTO user_details 
       (username, password_key, email, phone_number, date_of_birth, 
        validation_proof_type, proof_id_number, address, preferences, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        username,
        hashedPassword,
        email,
        phone_number || null,           // FIX: Converts "" to null
        date_of_birth || null,          // FIX: Converts "" to null
        validation_proof_type || null,  // FIX: Converts "" to null
        proof_id_number || null,        // FIX: Converts "" to null
        address || null,                // FIX: Converts "" to null
        JSON.stringify(preferences || {})
      ]
    );

  try {
    // Check if user already exists
    const [userExists] = await pool.execute(
      'SELECT * FROM user_details WHERE email = ? OR username = ?',
      [email, username]
    );

    if (userExists.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or username'
      });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create user (MySQL uses ? placeholders)
    const [result] = await pool.execute(
      `INSERT INTO user_details 
       (username, password_key, email, phone_number, date_of_birth, 
        validation_proof_type, proof_id_number, address, preferences, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        username,
        hashedPassword,
        email,
        phone_number,
        date_of_birth,
        validation_proof_type,
        proof_id_number,
        address,
        JSON.stringify(preferences || {})
      ]
    );

    // Get the inserted user (MySQL returns insertId)
    const [newUser] = await pool.execute(
      'SELECT user_id, username, email, phone_number, date_of_birth, created_at FROM user_details WHERE user_id = ?',
      [result.insertId]
    );

    // Generate JWT token
    const token = jwt.sign(
      { 
        user_id: newUser[0].user_id,
        email: newUser[0].email 
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      token,
      user: {
        user_id: newUser[0].user_id,
        username: newUser[0].username,
        email: newUser[0].email
      }
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during signup'
    });
  }
});

// Signin Route (MySQL)
router.post('/signin', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find user by email
    const [users] = await pool.execute(
      'SELECT * FROM user_details WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    const user = users[0];

    // Check password
    const validPassword = await bcrypt.compare(password, user.password_key);

    if (!validPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        user_id: user.user_id,
        email: user.email 
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Signin successful',
      token,
      user: {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        phone_number: user.phone_number
      }
    });

  } catch (error) {
    console.error('Signin error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during signin'
    });
  }
});

// Verify Token Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access token required'
    });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
    req.user = user;
    next();
  });
};

// Protected route example
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const [users] = await pool.execute(
      'SELECT user_id, username, email, phone_number, date_of_birth, address, preferences, created_at FROM user_details WHERE user_id = ?',
      [req.user.user_id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      user: users[0]
    });
  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Profile Update Route
router.put('/profile', authenticateToken, async (req, res) => {
  const { 
    username, email, dateOfBirth, 
    ...preferencesData // Groups bio, location, and all travel preferences together
  } = req.body;

  try {
    // 1. Fetch existing preferences to merge with new ones
    const [existingUsers] = await pool.execute(
      'SELECT preferences FROM user_details WHERE user_id = ?',
      [req.user.user_id]
    );

    if (existingUsers.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentPreferences = typeof existingUsers[0].preferences === 'string' 
      ? JSON.parse(existingUsers[0].preferences || '{}') 
      : (existingUsers[0].preferences || {});

    const updatedPreferences = { ...currentPreferences, ...preferencesData };

    // 2. Update the database
    await pool.execute(
      `UPDATE user_details 
       SET username = ?, email = ?, date_of_birth = ?, preferences = ? 
       WHERE user_id = ?`,
      [
        username, 
        email, 
        dateOfBirth || null, 
        JSON.stringify(updatedPreferences), 
        req.user.user_id
      ]
    );

    res.json({
      success: true,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ success: false, message: 'Server error updating profile' });
  }
});

module.exports = router;