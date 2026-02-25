import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/utils/currency_utils.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _showNeedsReviewOnly = false;

  // Mock data for demonstration
  final List<Transaction> _mockTransactions = [
    Transaction(
      id: 1,
      profileId: 1,
      accountId: 1,
      categoryId: 1,
      merchantId: 1,
      amountMinor: 95000000, // ₦950,000
      type: 'income',
      description: 'TechCorp Ltd',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      confidenceScore: 100,
      requiresReview: false,
    ),
    Transaction(
      id: 2,
      profileId: 1,
      accountId: 1,
      categoryId: 2,
      merchantId: 2,
      amountMinor: -4500, // ₦4,500
      type: 'expense',
      description: 'Chicken Republic',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      confidenceScore: 95,
      requiresReview: false,
    ),
    Transaction(
      id: 3,
      profileId: 1,
      accountId: 2,
      categoryId: 3,
      merchantId: 3,
      amountMinor: -2800, // ₦2,800
      type: 'expense',
      description: 'Bolt',
      timestamp: DateTime.now().subtract(const Duration(hours: 15)),
      confidenceScore: 92,
      requiresReview: false,
    ),
    Transaction(
      id: 4,
      profileId: 1,
      accountId: 1,
      categoryId: 4,
      merchantId: 4,
      amountMinor: -15000, // ₦15,000
      type: 'expense',
      description: 'IKEDC',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      confidenceScore: 88,
      requiresReview: false,
    ),
    Transaction(
      id: 5,
      profileId: 1,
      accountId: 1,
      categoryId: 5,
      merchantId: 5,
      amountMinor: -32000, // ₦32,000
      type: 'expense',
      description: 'Jumia',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      confidenceScore: 72,
      requiresReview: true,
      note: 'Could not determine exact merchant',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Use mock data for now
    final transactions = _mockTransactions;

    // Filter transactions based on selection
    final filteredTransactions = _getFilteredTransactions(transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications
            },
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2 transactions need review',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Low confidence - tap to verify merchant & category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showNeedsReviewOnly = !_showNeedsReviewOnly;
                              });
                            },
                            child: const Text('Show'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search and Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search merchants...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'All';
                            _showNeedsReviewOnly = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedFilter == 'All'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'All',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedFilter == 'All'
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'Needs Review';
                            _showNeedsReviewOnly = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedFilter == 'Needs Review'
                                ? Colors.red[500]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'Needs Review',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedFilter == 'Needs Review'
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_selectedFilter != 'Needs Review')
                                Positioned(
                                  top: 4,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start adding transactions to see them here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _TransactionCard(transaction: transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_showNeedsReviewOnly) {
      return transactions.where((t) => t.confidenceScore < 100).toList();
    }
    return transactions;
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Transaction Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      transaction.description,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(transaction.description),
                    color: _getCategoryColor(transaction.description),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant Name
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Category and Account
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getCategoryName(transaction.description),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'GTBank Savings', // Hardcoded for now
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Confidence Indicator
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(
                              transaction.confidenceScore,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${transaction.confidenceScore}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Amount
                        Text(
                          CurrencyUtils.formatMinorToDisplay(
                            transaction.amountMinor,
                            'NGN',
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: transaction.amountMinor >= 0
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),

                        // Transaction Type Arrow
                        const SizedBox(width: 4),
                        Icon(
                          transaction.amountMinor >= 0
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: transaction.amountMinor >= 0
                              ? Colors.green[600]
                              : Colors.red[600],
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date and Time
                    Text(
                      _formatDateTime(transaction.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            // Review Tag (if needed)
            if (transaction.confidenceScore < 100)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (transaction.note?.isNotEmpty == true)
                      Expanded(
                        child: Text(
                          ' - ${transaction.note}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? description) {
    switch (description?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
        return const Color(0xFF4CAF50); // Green for income
      case 'chicken republic':
        return const Color(0xFFFF6B35); // Orange for Food & Dining
      case 'bolt':
        return const Color(0xFF4285F4); // Blue for Transportation
      case 'ikedc':
        return const Color(0xFFF44336); // Red for Bills & Utilities
      case 'jumia':
        return const Color(0xFF9C27B0); // Purple for Shopping
      default:
        return Colors.grey[500]!;
    }
  }

  IconData _getCategoryIcon(String? description) {
    switch (description?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
        return Icons.payments; // Income icon
      case 'chicken republic':
        return Icons.restaurant; // Food icon
      case 'bolt':
        return Icons.directions_car; // Transport icon
      case 'ikedc':
        return Icons.receipt; // Bills icon
      case 'jumia':
        return Icons.shopping_cart; // Shopping icon
      default:
        return Icons.help_outline;
    }
  }

  String _getCategoryName(String? description) {
    switch (description?.toLowerCase()) {
      case 'techcorp ltd':
        return 'Salary';
      case 'chicken republic':
        return 'Food & Dining';
      case 'bolt':
        return 'Transportation';
      case 'ikedc':
        return 'Bills & Utilities';
      case 'jumia':
        return 'Shopping';
      default:
        return 'Uncategorized';
    }
  }

  Color _getConfidenceColor(int confidenceScore) {
    if (confidenceScore >= 95) return Colors.green;
    if (confidenceScore >= 80) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
