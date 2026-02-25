# Project Handoff: Personal Finance App

## Context
This Flutter project is being migrated from Windsurf to Google Antigravity. This document provides a comprehensive overview of the current codebase state for the new AI agent.

## Architecture Summary

### Clean Architecture Setup
- **State Management**: Riverpod (v2.5.1) for reactive state management
- **Database**: Drift (v2.18.0) with SQLite for local storage
- **Dependency Injection**: Provider pattern with Riverpod
- **Security**: SQLCipher encryption for sensitive data

### Technology Stack
- **Flutter**: v3.19.0+ with Material 3 design system
- **Database**: Drift ORM with SQLite, encrypted local storage
- **State**: Riverpod with Notifier pattern for complex state
- **Currency**: Multi-tier conversion system (online API → cache → fallback)
- **Notifications**: Local notifications with background service support

## Database Schema

### Core Tables (Drift Entities)
```dart
@DriftDatabase(tables: [
  Profiles,           // User profiles with currency preferences
  Accounts,           // Bank accounts and balances
  Categories,         // Transaction categories with icons/colors
  Merchants,          // Merchant information for AI categorization
  Tags,               // Flexible tagging system
  Transactions,        // Financial transactions with metadata
  Budgets,            // Budget tracking and limits
  RecurringRules,     // Automated transaction rules
  Goals,               // Financial goals tracking
  TransactionTags,    // Many-to-many transaction-tag relationship
])
```

### Database Features
- **Encrypted Storage**: SQLCipher for sensitive financial data
- **Offline-First**: All core functionality works without internet
- **Default Data**: Automatic profile/category creation on first launch
- **Migration Strategy**: Drift handles schema migrations automatically

## Completed Features

### ✅ Core Infrastructure
- **Database Initialization**: Complete Drift setup with encryption
- **Dependency Injection**: Full provider configuration in `core_providers.dart`
- **Currency System**: Hybrid offline/online currency conversion service
- **State Management**: Riverpod notifiers for accounts, transactions, analytics

### ✅ UI Components
- **Dashboard Screen**: Material 3 design with balance overview, recent transactions, review queue
- **Responsive Layout**: Proper Row overflow handling with Flexible/Expanded patterns
- **Form Widgets**: Custom formatted number inputs and validation
- **Navigation**: App router with deep linking support

### ✅ Services
- **Hybrid Currency Service**: 3-tier fallback system (API → cache → hardcoded)
- **Transaction Parser**: AI-powered transaction categorization
- **Notification Pipeline**: Background processing and smart notifications
- **Background Service**: Work manager setup for periodic tasks

### ✅ Testing
- **Currency Conversion**: Comprehensive test coverage for all conversion tiers
- **Database Operations**: Account DAO testing with currency validation
- **Integration Tests**: Real API testing and offline fallback verification

## Current Implementation Status

### 🟢 Production Ready
- **Dashboard**: Fully functional with balance cards, transaction lists, review queue
- **Account Management**: Complete CRUD operations with currency support
- **Transaction Flow**: Add, edit, categorize with AI assistance
- **Currency Conversion**: Robust offline-first conversion with multiple fallbacks

### 🟡 In Development
- **Transfer System**: Basic implementation exists, needs enhancement
- **Analytics**: Basic structure in place, needs comprehensive metrics
- **Settings Screen**: Basic preferences, needs more options
- **Export Features**: CSV export implemented, needs more formats

### 🔴 Not Started
- **Budget Management**: Table exists but no UI implementation
- **Goals Tracking**: Table exists but no UI implementation
- **Recurring Rules**: Table exists but no automation logic
- **Advanced Analytics**: Spending patterns, insights, predictions

## Strict Project Constraints

### 🚫 Non-Negotiable Requirements
1. **Offline-First Architecture**: 
   - No cloud database syncing or live-only API packages
   - All core features must work without internet connection
   - Local SQLite is the single source of truth

2. **Privacy-First Design**:
   - No third-party analytics or tracking services
   - All sensitive data encrypted at rest
   - User data never leaves device without explicit consent

3. **Material 3 Design System**:
   - Use Material 3 components and theming
   - Follow Google's Material Design guidelines
   - Ensure accessibility and platform consistency

4. **Riverpod State Management**:
   - Use Riverpod for all state management
   - Implement proper Notifier pattern for complex state
   - Avoid other state management solutions

5. **Local Database Only**:
   - SQLite with Drift ORM is the only persistence layer
   - No Firebase, Supabase, or other cloud databases
   - All data sync must be user-initiated (export/import)

## Pending Tasks (Priority Order)

### 🔥 High Priority
1. **Complete Transfer Screen Enhancement**
   - Add account selection with balance validation
   - Implement transfer confirmation flow
   - Add transfer history and status tracking

2. **Build Comprehensive Analytics Dashboard**
   - Spending by category trends
   - Monthly/yearly comparison charts
   - Budget vs actual spending analysis
   - Savings goal progress tracking

3. **Implement Budget Management UI**
   - Create budget categories and limits
   - Budget progress visualization
   - Overspending alerts and notifications

### 🟡 Medium Priority
4. **Add Goals Tracking Interface**
   - Create/edit financial goals
   - Goal progress visualization
   - Milestone celebrations and notifications

5. **Enhance Transaction Experience**
   - Advanced AI categorization
   - Recurring transaction automation
   - Bulk transaction operations

### 🟢 Low Priority
6. **Export/Import Features**
   - Multiple format support (JSON, PDF, OFX)
   - Cloud backup options (user-initiated)
   - Data migration between devices

7. **Settings and Preferences**
   - Advanced notification preferences
   - Currency display options
   - Theme customization options
   - Privacy and security settings

## Technical Notes

### Code Quality Standards
- **Linting**: Follow Dart/Flutter linting rules
- **Testing**: Minimum 80% test coverage for new features
- **Documentation**: Code comments for complex business logic
- **Error Handling**: Graceful degradation for offline scenarios

### Performance Considerations
- **Database Queries**: Optimize Drift queries for large datasets
- **UI Rendering**: Use const widgets and proper key management
- **Memory Management**: Dispose controllers and streams properly
- **Background Processing**: Efficient work manager configuration

### Security Implementation
- **Encryption**: SQLCipher for database files
- **API Keys**: Secure storage for external services
- **User Data**: No telemetry or analytics collection
- **Local Auth**: Secure authentication token storage

## Development Environment

### Current Branch Structure
```
lib/
├── application/          # Business logic and use cases
│   ├── services/         # External service integrations
│   └── use_cases/        # Application business rules
├── core/                # Shared utilities and configuration
│   ├── di/               # Dependency injection
│   ├── utils/            # Helper functions
│   └── errors/            # Custom error types
├── data/                 # Data layer implementation
│   ├── database/          # Drift database and DAOs
│   └── repositories/      # Repository pattern implementations
├── domain/               # Business entities and interfaces
│   ├── entities/          # Core data models
│   └── repositories/      # Repository interfaces
└── presentation/         # UI layer
    ├── providers/         # Riverpod state management
    ├── screens/           # App screens
    └── widgets/           # Reusable UI components
```

### Key Files to Understand
- `lib/data/database/app_database_simple.dart` - Main database configuration
- `lib/core/di/core_providers.dart` - Dependency injection setup
- `lib/application/services/hybrid_currency_service.dart` - Currency conversion logic
- `lib/presentation/screens/dashboard/dashboard_screen.dart` - Main UI implementation
- `lib/presentation/providers/transaction_providers.dart` - State management

## Next Steps for Antigravity

1. **Review Architecture**: Ensure understanding of Riverpod + Drift pattern
2. **Check Dependencies**: Verify all packages in pubspec.yaml are approved
3. **Run Tests**: Execute test suite to verify current functionality
4. **Start High Priority**: Begin with transfer screen enhancement
5. **Follow Constraints**: Maintain offline-first and privacy-first approach

## Contact Points

- **Technical Questions**: Database schema, state management patterns
- **Architecture Decisions**: Why certain technologies were chosen
- **Feature Clarification**: Business logic requirements and user flows
- **Constraint Discussions**: How to implement features within offline-first requirements

---

**Last Updated**: February 25, 2026
**Version**: 1.0.0+1
**Status**: Ready for Antigravity migration
