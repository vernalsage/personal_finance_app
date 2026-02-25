import '../entities/transaction.dart';
import '../repositories/itransaction_repository.dart';
import '../repositories/transaction_repository.dart';

/// Use case for executing atomic transfers between accounts
class ExecuteTransferUseCase {
  final ITransactionRepository _repository;

  ExecuteTransferUseCase(this._repository);

  /// Execute the use case to perform an atomic transfer
  Future<Result<void>> call({
    required int sourceAccountId,
    required int destinationAccountId,
    required int amountMinor,
    required String description,
    int? profileId = 1, // Default profile for MVP
    String? note,
  }) async {
    try {
      // Generate a unique transfer ID
      final transferId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create debit transaction (money out from source account)
      final debitTransaction = Transaction(
        id: 0, // Will be set by database
        profileId: profileId ?? 1,
        accountId: sourceAccountId,
        categoryId: 1, // Default category for MVP
        merchantId: 1, // Default merchant for MVP
        amountMinor: -amountMinor, // Negative for debit
        type: 'transfer_out',
        description: description,
        timestamp: DateTime.now(),
        confidenceScore: 100, // Manual transfer gets 100% confidence
        requiresReview: false, // Manual transfers don't require review
        note: note,
        transferId: transferId,
      );

      // Create credit transaction (money in to destination account)
      final creditTransaction = Transaction(
        id: 0, // Will be set by database
        profileId: profileId ?? 1,
        accountId: destinationAccountId,
        categoryId: 1, // Default category for MVP
        merchantId: 1, // Default merchant for MVP
        amountMinor: amountMinor, // Positive for credit
        type: 'transfer_in',
        description: description,
        timestamp: DateTime.now(),
        confidenceScore: 100, // Manual transfer gets 100% confidence
        requiresReview: false, // Manual transfers don't require review
        note: note,
        transferId: transferId,
      );

      // Save both transactions atomically
      final debitResult = await _repository.createTransaction(debitTransaction);
      if (debitResult.isFailure) {
        return Result.failure(
          'Failed to create debit transaction: ${debitResult.error}',
        );
      }

      final creditResult = await _repository.createTransaction(
        creditTransaction,
      );
      if (creditResult.isFailure) {
        return Result.failure(
          'Failed to create credit transaction: ${creditResult.error}',
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to execute transfer: $e');
    }
  }
}
