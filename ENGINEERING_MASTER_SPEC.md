# ENGINEERING_MASTER_SPEC.md

## Personal Finance & AI Coaching App (MVP)

### Version: 2.1 (Final Reviewed)

### Generated: 2026-02-22T10:07:40.547387 UTC

------------------------------------------------------------------------

# 1. AI CODING DIRECTIVE

You must:

-   Read entire document before writing code
-   Generate one module at a time
-   Avoid monolithic files
-   Always include unit tests for parsing logic
-   Prioritize financial correctness over UI speed

------------------------------------------------------------------------

# 2. CLEAN ARCHITECTURE RULES

UI → UseCase → Repository → DAO

-   UI must never access Drift directly
-   Business logic must not live in widgets
-   Parsing logic must not live in repositories
-   All service methods return Result`<T>`{=html} (Success/Failure)
-   No silent failures

------------------------------------------------------------------------

# 3. DATABASE INVARIANTS

## Monetary

-   No floating-point currency anywhere
-   All values stored as minor units

## Referential Integrity

-   All foreign keys enforced
-   Cascade delete where appropriate

## Consistency Invariant

After any transaction mutation:

-   Account balances must remain correct
-   Goal totals must remain correct
-   Budget totals must remain correct

Violation triggers full recomputation.

------------------------------------------------------------------------

# 4. NOTIFICATION DUPLICATE PREVENTION

-   Generate hash fingerprint of notification
-   Prevent duplicate insert within short time window
-   Store fingerprint only (not raw notification)

------------------------------------------------------------------------

# 5. MERCHANT RESOLUTION

1.  Normalize merchant string
2.  Query by normalizedName + profileId
3.  If not exists → create
4.  Update lastSeen

Must execute within DB transaction.

------------------------------------------------------------------------

# 6. BACKGROUND EXECUTION

-   Recurring rules executed via WorkManager
-   Backfill logic on app resume
-   Jobs must be idempotent
-   Unique work names required

------------------------------------------------------------------------

# 7. MIGRATION STRATEGY

-   Drift schema versioning mandatory
-   No destructive migrations in production
-   All migrations must preserve financial accuracy

------------------------------------------------------------------------

# 8. INDEXING STRATEGY

Mandatory indexes:

-   Transactions(profileId, timestamp)
-   Transactions(categoryId)
-   Transactions(merchantId)
-   Merchants(normalizedName, profileId)
-   Budgets(profileId, month, year)

------------------------------------------------------------------------

# 9. ATOMICITY REQUIREMENTS

Must run inside single DB transaction:

-   Transfer creation
-   Review resolution
-   Goal recalculation
-   Recurring creation

------------------------------------------------------------------------

# 10. DEFINITION OF DONE (MVP)

MVP complete when:

-   Parsing works for 3 banks
-   Merchant linking operational
-   No floating-point errors
-   Recurring backfill verified
-   Goals consistent after deletes
-   Transfers consistent
-   CSV validated in Power BI
-   Encrypted DB verified
-   Biometric lock enforced
-   Duplicate prevention verified

------------------------------------------------------------------------

Final Guarantee:

The system must never sacrifice financial correctness for convenience.
