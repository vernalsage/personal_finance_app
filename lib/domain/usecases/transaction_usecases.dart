import '../entities/transaction.dart';
import '../repositories/itransaction_repository.dart';
import '../repositories/merchant_repository.dart';
import '../core/result.dart';

/// Use case for creating a transaction
class CreateTransactionUseCase {
  final ITransactionRepository _repository;
  final MerchantRepository _merchantRepository;

  CreateTransactionUseCase(this._repository, this._merchantRepository);

  /// Execute the use case to create a transaction
  Future<Result<Transaction, Exception>> call(Transaction transaction) async {
    // Validate transaction
    if (transaction.amountMinor <= 0) {
      return Failure(Exception('Transaction amount must be positive'));
    }
    if (transaction.description.isEmpty) {
      return Failure(Exception('Transaction description is required'));
    }

    try {
      // 1) Normalize merchant string
      final normalizedName = _normalizeMerchantString(transaction.description);

      // 2) Call MerchantRepository to find it
      final merchantResult = await _merchantRepository.getOrCreateMerchant(
        transaction.profileId,
        transaction.description,
        normalizedName,
        categoryId: transaction.categoryId,
      );

      if (merchantResult.isFailure) {
        return Failure(Exception(merchantResult.failureData ?? 'Unknown merchant error'));
      }

      final merchant = merchantResult.successData!;

      // 3) Create Transaction entity using resolved merchantId
      final finalTransaction = Transaction(
        id: 0, // Will be set by database
        profileId: transaction.profileId,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        merchantId: merchant.id,
        amountMinor: transaction.amountMinor,
        type: transaction.type,
        description: transaction.description,
        timestamp: transaction.timestamp,
        confidenceScore: transaction.confidenceScore,
        requiresReview: transaction.requiresReview,
        note: transaction.note,
      );

      // 4) Call TransactionRepository.createTransaction()
      return await _repository.createTransaction(finalTransaction);
    } catch (e) {
      return Failure(Exception('Failed to create transaction: $e'));
    }
  }

  /// Normalize merchant string for consistent lookup
  String _normalizeMerchantString(String merchantName) {
    return merchantName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ' ');
  }
}

/// Use case for updating a transaction
class UpdateTransactionUseCase {
  UpdateTransactionUseCase(this._repository);

  final ITransactionRepository _repository;

  Future<Result<Transaction, Exception>> call(Transaction transaction) async {
    // Validate transaction
    if (transaction.amountMinor <= 0) {
      return Failure(Exception('Transaction amount must be positive'));
    }

    if (transaction.description.isEmpty) {
      return Failure(Exception('Transaction description is required'));
    }

    return await _repository.updateTransaction(transaction);
  }
}

/// Use case for deleting a transaction
class DeleteTransactionUseCase {
  DeleteTransactionUseCase(this._repository);

  final ITransactionRepository _repository;

  Future<Result<void, Exception>> call(int transactionId) async {
    return await _repository.deleteTransaction(transactionId);
  }
}

/// Use case for getting transactions requiring review
class GetTransactionsRequiringReviewUseCase {
  GetTransactionsRequiringReviewUseCase(this._repository);

  final ITransactionRepository _repository;

  Future<Result<List<Transaction>, Exception>> call(
    int profileId, {
    int? limit,
    int? offset,
  }) async {
    return await _repository.getTransactionsRequiringReview(profileId);
  }
}
