import express from 'express';
import { User } from '../models/User.js';
import { Plant } from '../models/Plant.js';
import { CareEvent } from '../models/CareEvent.js';
import { SyncOperation } from '../models/SyncOperation.js';
import { verifyPassword } from '../utils/password.js';

const router = express.Router();

function renderPage({ error = null, success = null, email = '' } = {}) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SpryFlora - Account & Data Deletion Request</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary-green: #2E7D32;
      --light-green: #E8F5E9;
      --accent-green: #4CAF50;
      --alert-red: #D32F2F;
      --light-red: #FFEBEE;
      --text-dark: #1C2D1F;
      --text-muted: #5F7362;
      --card-bg: #FFFFFF;
      --page-bg: #F4F8F4;
      --border-color: #DDE7DD;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Nunito', sans-serif;
      background-color: var(--page-bg);
      color: var(--text-dark);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px 16px;
      line-height: 1.5;
    }

    .container {
      width: 100%;
      max-width: 520px;
      background-color: var(--card-bg);
      border-radius: 24px;
      border: 1.5px solid var(--border-color);
      box-shadow: 0 10px 30px rgba(46, 125, 50, 0.08);
      overflow: hidden;
    }

    .header {
      background: linear-gradient(135deg, #1B5E20 0%, #2E7D32 60%, #43A047 100%);
      color: white;
      padding: 32px 24px;
      text-align: center;
    }

    .header-logo {
      font-size: 42px;
      margin-bottom: 8px;
    }

    .header h1 {
      font-size: 24px;
      font-weight: 900;
      margin-bottom: 6px;
    }

    .header p {
      font-size: 14px;
      opacity: 0.9;
      font-weight: 600;
    }

    .content {
      padding: 28px 24px;
    }

    .alert {
      padding: 14px 16px;
      border-radius: 14px;
      font-size: 14px;
      font-weight: 700;
      margin-bottom: 20px;
      display: flex;
      align-items: flex-start;
      gap: 10px;
    }

    .alert-danger {
      background-color: var(--light-red);
      color: var(--alert-red);
      border: 1px solid #FFCDD2;
    }

    .alert-success {
      background-color: var(--light-green);
      color: var(--primary-green);
      border: 1px solid #C8E6C9;
    }

    .info-box {
      background-color: #FFFDE7;
      border: 1px solid #FFF59D;
      border-radius: 14px;
      padding: 14px 16px;
      font-size: 13.5px;
      color: #795548;
      margin-bottom: 22px;
      font-weight: 600;
    }

    .info-box ul {
      margin-top: 8px;
      padding-left: 20px;
    }

    .info-box li {
      margin-bottom: 4px;
    }

    .form-group {
      margin-bottom: 18px;
    }

    label {
      display: block;
      font-size: 13.5px;
      font-weight: 800;
      color: var(--text-dark);
      margin-bottom: 6px;
    }

    input[type="email"],
    input[type="password"],
    select,
    textarea {
      width: 100%;
      padding: 12px 14px;
      border: 1.5px solid var(--border-color);
      border-radius: 12px;
      font-family: 'Nunito', sans-serif;
      font-size: 14px;
      color: var(--text-dark);
      background-color: #FAFAFA;
      transition: all 0.2s ease;
    }

    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--accent-green);
      background-color: #FFFFFF;
      box-shadow: 0 0 0 3px rgba(76, 175, 80, 0.15);
    }

    .checkbox-group {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      margin-top: 20px;
      margin-bottom: 24px;
    }

    .checkbox-group input[type="checkbox"] {
      width: 18px;
      height: 18px;
      accent-color: var(--alert-red);
      margin-top: 2px;
      cursor: pointer;
    }

    .checkbox-group label {
      font-size: 13px;
      font-weight: 700;
      color: var(--text-dark);
      cursor: pointer;
      line-height: 1.4;
    }

    .btn-delete {
      width: 100%;
      background: linear-gradient(135deg, #D32F2F 0%, #B71C1C 100%);
      color: white;
      border: none;
      border-radius: 14px;
      padding: 15px;
      font-size: 15px;
      font-weight: 900;
      cursor: pointer;
      box-shadow: 0 4px 12px rgba(211, 47, 47, 0.25);
      transition: transform 0.15s ease, box-shadow 0.15s ease;
    }

    .btn-delete:hover {
      transform: translateY(-1px);
      box-shadow: 0 6px 16px rgba(211, 47, 47, 0.35);
    }

    .btn-delete:active {
      transform: translateY(1px);
    }

    .footer {
      text-align: center;
      padding: 16px;
      font-size: 12px;
      color: var(--text-muted);
      border-top: 1px solid var(--border-color);
      background-color: #FAFCFA;
      font-weight: 700;
    }
  </style>
</head>
<body>

  <div class="container">
    <div class="header">
      <div class="header-logo">🌱</div>
      <h1>SpryFlora</h1>
      <p>Account & Personal Data Deletion Request</p>
    </div>

    <div class="content">
      ${success ? `
        <div class="alert alert-success">
          <div>
            <strong>✅ Account & Data Successfully Deleted</strong><br>
            ${success}
          </div>
        </div>
        <p style="text-align: center; color: var(--text-muted); font-weight: 700; font-size: 14px; margin-top: 20px;">
          You may close this browser window now. Thank you for using SpryFlora.
        </p>
      ` : `
        ${error ? `
          <div class="alert alert-danger">
            <div>
              <strong>❌ Deletion Failed</strong><br>
              ${error}
            </div>
          </div>
        ` : ''}

        <div class="info-box">
          <strong>⚠️ Warning: Permanent Action</strong>
          <p>Submitting this request will permanently remove:</p>
          <ul>
            <li>Your SpryFlora account credentials and profile</li>
            <li>All tracked plant data, growth history & garden logs</li>
            <li>Care events, achievements, and offline sync records</li>
          </ul>
        </div>

        <form action="/delete-account" method="POST">
          <div class="form-group">
            <label for="email">Account Email Address *</label>
            <input type="email" id="email" name="email" value="${email}" required placeholder="your.email@example.com">
          </div>

          <div class="form-group">
            <label for="password">Account Password *</label>
            <input type="password" id="password" name="password" required placeholder="Enter your password to verify">
          </div>

          <div class="form-group">
            <label for="reason">Reason for Deletion (Optional)</label>
            <select id="reason" name="reason">
              <option value="">Select a reason...</option>
              <option value="no_longer_using">No longer using the application</option>
              <option value="privacy_concerns">Privacy & data concerns</option>
              <option value="new_account">Creating a new account</option>
              <option value="other">Other reason</option>
            </select>
          </div>

          <div class="form-group">
            <label for="comments">Additional Details (Optional)</label>
            <textarea id="comments" name="comments" rows="3" placeholder="Tell us how we can improve SpryFlora..."></textarea>
          </div>

          <div class="checkbox-group">
            <input type="checkbox" id="confirm" name="confirm" required>
            <label for="confirm">
              I understand that deleting my account is immediate and permanent. All my plants, records, and progress will be permanently erased.
            </label>
          </div>

          <button type="submit" class="btn-delete">🗑️ Permanently Delete My Account</button>
        </form>
      `}
    </div>

    <div class="footer">
      SpryFlora Botanical Companion • Google Play Policy Compliant Account Deletion Portal
    </div>
  </div>

</body>
</html>`;
}

// GET /delete-account
router.get('/', (req, res) => {
  res.setHeader('Content-Type', 'text/html');
  res.status(200).send(renderPage());
});

// POST /delete-account
router.post('/', async (req, res) => {
  const { email, password, confirm } = req.body || {};

  res.setHeader('Content-Type', 'text/html');

  if (!email || !password) {
    return res.status(400).send(
      renderPage({
        error: 'Please provide both your account email address and password.',
        email: email || '',
      })
    );
  }

  if (!confirm) {
    return res.status(400).send(
      renderPage({
        error: 'You must check the confirmation checkbox to proceed with account deletion.',
        email: email || '',
      })
    );
  }

  try {
    const cleanEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: cleanEmail }).select('+passwordHash');

    if (!user) {
      return res.status(401).send(
        renderPage({
          error: 'No account found with the provided email address. Please check your credentials.',
          email,
        })
      );
    }

    const isValidPassword = await verifyPassword(user.passwordHash, password);
    if (!isValidPassword) {
      return res.status(401).send(
        renderPage({
          error: 'Incorrect password. Please verify your password and try again.',
          email,
        })
      );
    }

    const userId = user._id;

    // Perform cascade deletion of user records
    await Plant.deleteMany({ userId });
    await CareEvent.deleteMany({ userId });
    await SyncOperation.deleteMany({ userId });
    await User.findByIdAndDelete(userId);

    return res.status(200).send(
      renderPage({
        success: `Account <strong>${cleanEmail}</strong> and all associated plants, logs, and stored data have been permanently deleted from SpryFlora servers.`,
      })
    );
  } catch (error) {
    console.error('Account deletion error:', error);
    return res.status(500).send(
      renderPage({
        error: 'An internal server error occurred while deleting your account. Please try again later.',
        email,
      })
    );
  }
});

export default router;
