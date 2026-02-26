import '../../domain/entities/transaction.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../domain/core/result.dart' as domain_result;
import '../../core/utils/string_utils.dart';

/// Use case for adding a transaction with merchant logic
class AddTransactionUseCase {
  AddTransactionUseCase(this._transactionRepository, this._merchantRepository);

  final ITransactionRepository _transactionRepository;
  final MerchantRepository _merchantRepository;

  /// Add a transaction with merchant resolution logic
  ///
  /// Takes a raw merchant string, resolves or creates the merchant,
  /// then saves the transaction with the correct merchantId
  Future<domain_result.Result<Transaction, Exception>> call({
    required int profileId,
    required int accountId,
    required int categoryId,
    required String merchantName,
    required int amountMinor,
    required String type,
    required String description,
    required DateTime timestamp,
    int? confidenceScore,
    bool? requiresReview,
    String? note,
  }) async {
    try {
      // Normalize merchant name for lookup
      final normalizedName = StringUtils.normalizeMerchantName(merchantName);

      // Try to find existing merchant by name
      final existingMerchantResult = await _merchantRepository
          .getMerchantByName(profileId, normalizedName);

      Merchant merchant;

      if (existingMerchantResult.isSuccess &&
          existingMerchantResult.successData != null) {
        // Merchant exists
        merchant = existingMerchantResult.successData!;
        // Note: updateLastSeen deferred or handled via updateMerchant if needed
      } else {
        // Merchant doesn't exist, create new one
        final createMerchantResult = await _merchantRepository
            .getOrCreateMerchant(profileId, merchantName, normalizedName);

        if (createMerchantResult.isFailure) {
          return domain_result.Failure(
            Exception(
              'Failed to create merchant: ${createMerchantResult.failureData}',
            ),
          );
        }

        merchant = createMerchantResult.successData!;
      }

      // Create transaction with the resolved merchant
      final transaction = Transaction(
        id: 0, // Will be set by database
        profileId: profileId,
        accountId: accountId,
        categoryId: categoryId,
        merchantId: merchant.id,
        amountMinor: amountMinor,
        type: type,
        description: description,
        timestamp: timestamp,
        confidenceScore: confidenceScore ?? 100,
        requiresReview: requiresReview ?? false,
        note: note,
      );

      // Save the transaction
      final result = await _transactionRepository.createTransaction(
        transaction,
      );

      if (result.isFailure) {
        return domain_result.Failure(Exception('Failed to create transaction: ${result.failureData}'));
      }

      return domain_result.Success(result.successData!);
    } catch (e) {
      return domain_result.Failure(Exception('Failed to add transaction: $e'));
    }
  }
}
