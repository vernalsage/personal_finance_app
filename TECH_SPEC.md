# TECH_SPEC.md

## Personal Finance & AI Coaching App (MVP)

### Version: 2.1 (Final Reviewed)

### Generated: 2026-02-22T10:07:40.547387 UTC

------------------------------------------------------------------------

# 1. PROJECT OVERVIEW

A privacy-first, offline-capable Android personal finance application
built using AI-assisted development.

The application:

-   Parses bank notifications (no SMS permissions required)
-   Stores all financial data locally using encrypted SQLite (SQLCipher)
-   Uses integer minor currency units (no floating-point storage)
-   Implements deterministic budgeting and forecasting engines
-   Exports analytics-ready star schema for Power BI (including time
    dimension)
-   Guarantees financial accuracy and relational integrity

**Product Philosophy:** Local-first. Deterministic-first. Intelligence
layered on top. User-controlled.

------------------------------------------------------------------------

# 2. PLATFORM & ARCHITECTURE

## 2.1 Technology Stack

-   Flutter (Material 3)
-   Dart (Null-safe)
-   Riverpod (State + Dependency Injection)
-   Drift (SQLite ORM)
-   SQLCipher (Database Encryption)
-   flutter_secure_storage (Key storage)
-   WorkManager (Background tasks)
-   notification_listener_service
-   flutter_local_notifications
-   local_auth (Biometric lock)

------------------------------------------------------------------------

# 3. DATA MODEL PRINCIPLES

## 3.1 Monetary Rule (Non-Negotiable)

-   All monetary values stored as IntColumn (minor units, e.g., Kobo)
-   Never use floating-point (RealColumn) for money
-   UI handles decimal formatting only
-   Export converts minor units to decimal representation

Example: ₦5,000 → 500000 (stored)

------------------------------------------------------------------------

## 3.2 Star Schema Integrity

Fact: - Transactions

Dimensions: - Profiles - Accounts - Categories - Merchants - Tags - Time
(materialized at export)

No denormalized merchant names in Transactions table.

------------------------------------------------------------------------

# 4. MVP FEATURE LOCK

Included:

-   Multi-profile support
-   Multi-account (Bank, Cash, Credit, Wallet)
-   Transfers (dual-entry linked transactions)
-   Manual entry
-   Notification parsing with confidence scoring
-   Merchant normalization
-   Monthly budgets (80% alert threshold)
-   Monthly recurring rules
-   Goals (basic with cached totals)
-   Tags
-   Cash runway
-   Financial stability score
-   CSV export (Power BI ready)
-   Biometric lock
-   Encrypted database

Excluded:

-   Cloud sync
-   Attachments
-   Widgets
-   Advanced recurrence rules
-   AI chat interface
-   PDF export
-   Multi-device sync

------------------------------------------------------------------------

# 5. NOTIFICATION PARSING PIPELINE

1.  Capture notification
2.  Filter by approved package names
3.  Deterministic regex extraction
4.  Confidence scoring (threshold = 80)
5.  Merchant normalization + linking
6.  Persist transaction
7.  If confidence \< 80 → requiresReview = true

Raw notification text must not be permanently stored.

------------------------------------------------------------------------

# 6. REVIEW QUEUE RESOLUTION

When resolving a flagged transaction:

-   Update categoryId and/or merchantId
-   Set requiresReview = false
-   Set confidenceScore = 100
-   Recalculate Goal totals, Budget usage, Runway, Stability score

All operations must execute atomically.

------------------------------------------------------------------------

# 7. RECURRING RULE ENGINE

## 7.1 Execution Strategy

-   WorkManager scheduled daily
-   On app launch: check and backfill overdue recurring rules
-   Jobs must be idempotent

## 7.2 Battery Optimization Handling

-   Inform user that battery optimization may delay background execution
-   Provide deep link to system settings
-   Do NOT force restricted permissions
-   Do NOT block functionality if declined

------------------------------------------------------------------------

# 8. GOAL ENGINE

-   Source of truth = sum of linked transactions
-   currentAmountMinor = cached value only
-   On insert/update/delete → recalc totals
-   Inconsistency detection triggers full recomputation

------------------------------------------------------------------------

# 9. TRANSFER LOGIC

-   Create two transactions sharing transferId
-   Debit source, credit destination
-   Excluded from income/expense calculations
-   Must be atomic

------------------------------------------------------------------------

# 10. EXPORT ENGINE

Must generate:

-   Fact_Transactions.csv
-   Dim_Profiles.csv
-   Dim_Accounts.csv
-   Dim_Categories.csv
-   Dim_Merchants.csv
-   Dim_Tags.csv
-   Bridge_TransactionTags.csv
-   Dim_Time.csv

## 10.1 Time Dimension

-   Generate between min/max transaction dates
-   Include DateId (YYYYMMDD), ISO date, Year, Month, Quarter,
    DayOfWeek, IsWeekend

------------------------------------------------------------------------

# 11. SECURITY REQUIREMENTS

-   SQLCipher encryption
-   Hardware-backed keystore
-   No plaintext financial data persisted
-   FLAG_SECURE enabled
-   Auto-lock after 60 seconds
-   Offline-capable core functionality

------------------------------------------------------------------------

# 12. PERFORMANCE TARGETS

-   Cold start \< 2 seconds
-   Parsing \< 300ms deterministic path
-   Indexed queries mandatory
-   No N+1 query patterns

------------------------------------------------------------------------

End of TECH_SPEC.md
