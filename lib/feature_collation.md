# Personal Finance App - Feature Collation

This document catalogs the current functional features of the application, stabilized and verified as of Phase 10.

## 1. Core Financial Engine
- **Multi-Account Management**: Support for Bank, Cash, Credit, and Wallet accounts with custom starting balances.
- **Signed Transaction Tracking**: Transactions are stored with explicit signs (negative for expenses, positive for income) ensuring consistent history and balance calculation.
- **Atomic Transfers**: Dual-entry system for moving funds between accounts with a shared `transferId` to maintain integrity.
- **Multi-Currency Support**: Real-time conversion (with 3-tier fallback) for global balance calculation in NGN.

## 2. Intelligence & Automation
- **Notification Parsing Pipeline**: Automated, deterministic extraction of transactions from bank notifications (OPay, Zenith, GTBank) with confidence scoring.
- **Merchant Normalization**: Automatic cleanup of messy SMS merchant names into readable entities.
- **Recurring Rules**: Schedule-based automation for monthly bills and income with idempotent execution.

## 3. Financial Planning
- **Monthly Budgets**: Category-based spending limits with real-time usage tracking and "80% alert" thresholds.
- **Savings Goals**: Milestone-based tracking linked to transactions, showing percentage progress and target dates.

## 4. Analytics & Insights
- **Expense Breakdown**: Visualizing spending across categories.
- **Weekly Spending Trends**: Tracking cash flow over time.
- **Cash Runway & Stability Score**: Predictive metrics for financial health.

## 5. Privacy & Security
- **Encrypted Database**: SQLCipher protection for all local financial data.
- **Biometric Lock**: Fingerprint/FaceID protection for app entry and settings.
- **Privacy-First Notifications**: Direct parsing without permanent storage of raw notification text.
