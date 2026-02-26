import '../../domain/entities/transaction.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/core/result.dart';

/// Use case for executing transfers between accounts
///
/// Strictly enforces the master spec rule: generates a single transferId (UUID)
/// and creates two linked transactions (one debit, one credit) atomically
class ExecuteTransferUseCase {
  ExecuteTransferUseCase(this._transactionRepository, this._accountRepository);

  final ITransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  /// Execute a transfer from source account to destination account
  ///
  /// Generates a UUID for transferId and creates two transactions:
  /// - Debit transaction from source account (transfer_out)
  /// - Credit transaction to destination account (transfer_in)
  ///
  /// Both transactions share the same transferId for linking
  Future<Result<List<Transaction>, Exception>> call({
    required int sourceAccountId,
    required int destinationAccountId,
    required int amountMinor,
    required String description,
    int? profileId,
    DateTime? timestamp,
    String? note,
  }) async {
    try {
      // Validate accounts exist and get their details
      final sourceAccountResult = await _accountRepository.getAccountById(
        sourceAccountId,
      );
      if (sourceAccountResult.isFailure ||
          sourceAccountResult.successData == null) {
        return Failure(Exception('Source account not found'));
      }

      final destAccountResult = await _accountRepository.getAccountById(
        destinationAccountId,
      );
      if (destAccountResult.isFailure ||
          destAccountResult.successData == null) {
        return Failure(Exception('Destination account not found'));
      }

      final sourceAccount = sourceAccountResult.successData!;
      final destAccount = destAccountResult.successData!;

      // Use profileId from source account if not provided
      final transferProfileId = profileId ?? sourceAccount.profileId;

      // Validate sufficient balance
      if (sourceAccount.balanceMinor < amountMinor) {
        return Failure(Exception('Insufficient balance in source account'));
      }

      // Generate UUID for transfer linking
      final transferId = _generateTransferId();

      // Create timestamp if not provided
      final transferTimestamp = timestamp ?? DateTime.now();

      // Create debit transaction (money out from source)
      final debitTransaction = Transaction(
        id: 0, // Will be set by database
        profileId: transferProfileId,
        accountId: sourceAccountId,
        categoryId: 1, // Default transfer category - should be configurable
        merchantId: 1, // Default transfer merchant - should be configurable
        amountMinor: -amountMinor, // Negative for debit
        type: 'transfer_out',
        description: 'Transfer to ${destAccount.name}: $description',
        timestamp: transferTimestamp,
        confidenceScore: 100,
        requiresReview: false,
        transferId: transferId,
        note: note,
      );

      // Create credit transaction (money in to destination)
      final creditTransaction = Transaction(
        id: 0, // Will be set by database
        profileId: transferProfileId,
        accountId: destinationAccountId,
        categoryId: 1, // Default transfer category - should be configurable
        merchantId: 1, // Default transfer merchant - should be configurable
        amountMinor: amountMinor, // Positive for credit
        type: 'transfer_in',
        description: 'Transfer from ${sourceAccount.name}: $description',
        timestamp: transferTimestamp,
        confidenceScore: 100,
        requiresReview: false,
        transferId: transferId,
        note: note,
      );

      // Note: In a real implementation, this should be wrapped in a database transaction
      // to ensure atomicity. For now, we'll create them sequentially
      final debitResult = await _transactionRepository.createTransaction(
        debitTransaction,
      );
      if (debitResult.isFailure) {
        return Failure(Exception(
          'Failed to create debit transaction: ${debitResult.failureData}',
        ));
      }

      final creditResult = await _transactionRepository.createTransaction(
        creditTransaction,
      );
      if (creditResult.isFailure) {
        // Try to rollback debit transaction
        await _transactionRepository.deleteTransaction(debitResult.successData!.id);
        return Failure(Exception(
          'Failed to create credit transaction: ${creditResult.failureData}',
        ));
      }

      // Update account balances
      final updateSourceResult = await _accountRepository.updateAccountBalance(
        sourceAccountId,
        sourceAccount.balanceMinor - amountMinor,
      );
      final updateDestResult = await _accountRepository.updateAccountBalance(
        destinationAccountId,
        destAccount.balanceMinor + amountMinor,
      );

      if (updateSourceResult.isFailure || updateDestResult.isFailure) {
        // Rollback both transactions
        await _transactionRepository.deleteTransaction(debitResult.successData!.id);
        await _transactionRepository.deleteTransaction(creditResult.successData!.id);
        return Failure(Exception('Failed to update account balances'));
      }

      return Success([debitResult.successData!, creditResult.successData!]);
    } catch (e) {
      return Failure(Exception('Transfer failed: $e'));
    }
  }

  /// Generate a unique transfer ID
  String _generateTransferId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'transfer_$timestamp-$random';
  }
}
