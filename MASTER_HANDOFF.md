# Master Handoff: Personal Finance App

## Context
This Flutter project is being migrated to Google Stitch (UX/UI recreation) and Antigravity (logic and architecture). This document provides comprehensive guidelines for both teams, with detailed Design System & UX Guidelines for Stitch and complete architectural documentation for Antigravity.

---

## 🎨 Design System & UX Guidelines (Stitch Team)

### Visual Identity

#### Primary Color Palette
```dart
// Primary Brand Colors
const Color primaryTeal = Color(0xFF0D5C58);        // Main brand accent
const Color primaryTealLight = Color(0xFF1A7A74);   // Light variant
const Color primaryTealDark = Color(0xFF0A4541);    // Dark variant

// Semantic Colors
const Color successGreen = Color(0xFF2E7D32);        // Credit/Income
const Color errorRed = Color(0xFFC62828);           // Debit/Expense
const Color warningOrange = Color(0xFFFF6B35);      // Food & Dining category
const Color infoBlue = Color(0xFF1976D2);           // Information/Badges

// Neutral Colors
const Color backgroundPrimary = Color(0xFFF8F9FA);  // Main background
const Color backgroundCard = Color(0xFFFFFFFF);     // Card backgrounds
const Color textPrimary = Color(0xFF212121);         // Primary text
const Color textSecondary = Color(0xFF757575);      // Secondary text
const Color borderLight = Color(0xFFE0E0E0);         // Subtle borders
```

#### Category Color System
```dart
// Predefined Category Colors
const Map<String, Color> categoryColors = {
  'techcorp ltd': Color(0xFF4CAF50),      // Salary/Income
  'salary': Color(0xFF4CAF50),
  'chicken republic': Color(0xFFFF6B35),  // Food & Dining
  'bolt': Color(0xFF4285F4),              // Transportation
  'ikedc': Color(0xFFF44336),             // Utilities
  'jumia': Color(0xFF9C27B0),             // Shopping
  'default': Colors.grey[500]!,
};
```

### Component Anatomy

#### Premium Metric Cards
```dart
// Structure for all metric cards (balance, transactions, etc.)
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top: Label
        Text(
          'Total Balance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        // Middle: Main Value
        Text(
          '₦125,000.00',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        // Bottom: Optional subtitle/metadata
        if (subtitle != null) ...[
          SizedBox(height: 4),
          Text(subtitle, style: subtitleStyle),
        ],
      ],
    ),
  ),
)
```

#### Transaction Review Cards
```dart
// Structure for transaction items requiring review
Card(
  margin: EdgeInsets.only(bottom: 8),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        // Left: Category Icon (40x40)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        // Middle: Transaction Details (Expanded)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                merchantName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              // Category & Account Badges Row
              Row(
                children: [
                  Flexible(
                    child: _buildBadge(categoryName, Colors.grey[100]!, infoBlue),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildBadge(accountName, Colors.blue[50]!, infoBlue),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Right: Amount
        Text(
          amountText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? successGreen : errorRed,
          ),
        ),
      ],
    ),
  ),
)
```

#### Badge Component
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: textColor,
      fontWeight: FontWeight.w500,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  ),
)
```

### Typography & Copy

#### Dynamic Greeting Logic
```dart
String _getGreeting() {
  final hour = DateTime.now().hour;
  final name = 'Deolu'; // TODO: Get from user profile
  
  if (hour < 12) {
    return 'Good morning, $name';
  } else if (hour < 17) {
    return 'Good afternoon, $name';
  } else {
    return 'Good evening, $name';
  }
}
```

#### Standard Copy & Messaging
```dart
// Empty States
const String noTransactionsYet = 'No transactions yet';
const String noAccountsYet = 'No accounts added yet';
const String noDataAvailable = 'No data available';

// Error States
const String errorLoadingBalance = 'Error loading balance';
const String errorLoadingTransactions = 'Error loading transactions';
const String genericErrorMessage = 'Something went wrong';

// Success States
const String accountAddedSuccessfully = 'Account added successfully';
const String transactionAddedSuccessfully = 'Transaction added successfully';
const String transferCompletedSuccessfully = 'Transfer completed successfully';

// Loading States
const String loadingBalance = 'Loading...';
const String loadingTransactions = 'Loading transactions...';
const String processing = 'Processing...';

// Review Queue Messaging
const String transactionsNeedReview = 'transactions need review';
const String lowConfidenceMessage = 'Low confidence - tap to verify merchant & category';
const String showButton = 'Show';
const String viewAll = 'View All';
```

#### Text Style Hierarchy
```dart
// Primary Headings
TextStyle headlineLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: textPrimary,
);

// Card Titles
TextStyle titleMedium = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: textPrimary,
);

// Secondary Text
TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  color: textSecondary,
);

// Small Text (timestamps, badges)
TextStyle bodySmall = TextStyle(
  fontSize: 12,
  color: textSecondary,
);
```

### Layout Rules & Patterns

#### Row Overflow Prevention (Critical Pattern)
```dart
// ALWAYS use this pattern for Rows with text content
Row(
  children: [
    // First element: Flexible (can shrink if needed)
    Flexible(
      child: Text(
        'Long text that might overflow',
        style: TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    SizedBox(width: 8),
    // Second element: Expanded (takes remaining space)
    Expanded(
      child: Text(
        'Secondary text',
        style: TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    // Fixed width elements (buttons, icons)
    Icon(Icons.arrow_forward, size: 16),
  ],
),
```

#### Card Spacing System
```dart
// Standard spacing between cards
const EdgeInsets cardMargin = EdgeInsets.only(bottom: 8);
const EdgeInsets cardPadding = EdgeInsets.all(16);
const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);

// Section spacing
const SizedBox sectionSpacing = SizedBox(height: 24);
const SizedBox itemSpacing = SizedBox(height: 16);
const SizedBox smallSpacing = SizedBox(height: 8);
```

#### Responsive Layout Patterns
```dart
// Main screen structure
SingleChildScrollView(
  padding: EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Section
      _buildHeader(),
      sectionSpacing,
      
      // Balance Card
      _buildBalanceCard(),
      sectionSpacing,
      
      // Review Section (conditional)
      if (hasReviewTransactions) ...[
        _buildReviewSection(),
        sectionSpacing,
      ],
      
      // Recent Transactions
      _buildRecentTransactions(),
    ],
  ),
)
```

#### Icon Usage Guidelines
```dart
// Category Icons (20px inside 40px containers)
Icon(Icons.restaurant, size: 20)           // Food & Dining
Icon(Icons.directions_car, size: 20)        // Transportation
Icon(Icons.shopping_cart, size: 20)        // Shopping
Icon(Icons.movie, size: 20)                 // Entertainment
Icon(Icons.receipt, size: 20)              // Bills & Utilities
Icon(Icons.local_hospital, size: 20)        // Healthcare
Icon(Icons.school, size: 20)               // Education
Icon(Icons.payments, size: 20)             // Salary/Income
Icon(Icons.trending_up, size: 20)          // Investment
Icon(Icons.more_horiz, size: 20)           // Other

// Action Icons (24px)
Icon(Icons.add, size: 24)                   // Add/Create
Icon(Icons.arrow_forward, size: 24)        // Navigate forward
Icon(Icons.settings, size: 24)              // Settings
Icon(Icons.download, size: 24)             // Export/Download
```

#### Animation & Micro-interactions
```dart
// Standard card tap animation
InkWell(
  borderRadius: BorderRadius.circular(12),
  onTap: () => navigateToDetail(),
  child: Card(/* card content */),
)

// Loading states
CircularProgressIndicator() // For primary loading
LinearProgressIndicator() // For progress bars

// Success/Error feedback
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message),
    backgroundColor: isSuccess ? Colors.green : Colors.red,
  ),
)
```

---

## 🏗️ Architecture Summary (Antigravity Team)

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

## Next Steps for Teams

### For Stitch (UX/UI Team)
1. **Study Design System**: Understand the color palette, component anatomy, and layout rules
2. **Implement Patterns**: Apply the Row overflow prevention pattern consistently
3. **Maintain Consistency**: Use the defined typography hierarchy and spacing system
4. **Follow Guidelines**: Adhere to the Material 3 design system and accessibility standards

### For Antigravity (Architecture Team)
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
- **Design System Questions**: Color usage, component patterns, layout rules

---

**Last Updated**: February 25, 2026
**Version**: 1.0.0+1
**Status**: Ready for Stitch + Antigravity migration
**Teams**: Stitch (UX/UI), Antigravity (Architecture/Logic)
