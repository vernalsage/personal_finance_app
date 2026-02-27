import '../repositories/itransaction_repository.dart';
import '../repositories/account_repository.dart';
import '../core/result.dart';
import '../../application/services/hybrid_currency_service.dart';

/// Use case for executing atomic transfers between accounts
class ExecuteTransferUseCase {
  final ITransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  ExecuteTransferUseCase(this._transactionRepository, this._accountRepository);

  /// Execute the use case to perform an atomic transfer
  Future<Result<void, Exception>> call({
    required int sourceAccountId,
    required int destinationAccountId,
    required int amountMinor,
    required String description,
    int? profileId = 1, // Default profile for MVP
    String? note,
  }) async {
    try {
      final pId = profileId ?? 1;

      // 1. Fetch account details to check currencies
      final sourceResult = await _accountRepository.getAccountById(sourceAccountId);
      final destResult = await _accountRepository.getAccountById(destinationAccountId);

      if (sourceResult.isFailure || sourceResult.successData == null) {
        return Failure(Exception('Source account not found'));
      }
      if (destResult.isFailure || destResult.successData == null) {
        return Failure(Exception('Destination account not found'));
      }

      final sourceAccount = sourceResult.successData!;
      final destAccount = destResult.successData!;

      int toAmountMinor = amountMinor;

      // 2. Handle multi-currency conversion if necessary
      if (sourceAccount.currency != destAccount.currency) {
        final amount = amountMinor / 100.0;
        final rate = await HybridCurrencyService.convertCurrency(
          amount: 1.0,
          fromCurrency: sourceAccount.currency,
          toCurrency: destAccount.currency,
        );
        toAmountMinor = (amount * rate * 100).round();
      }

      // 3. Use the repository's dedicated transfer method which is atomic in the DAO
      final result = await _transactionRepository.createTransfer(
        profileId: pId,
        fromAccountId: sourceAccountId,
        toAccountId: destinationAccountId,
        fromAmountMinor: amountMinor,
        toAmountMinor: toAmountMinor,
        description: description,
        timestamp: DateTime.now(),
        note: note,
      );

      return result.map((_) => null);
    } catch (e) {
      return Failure(Exception('Failed to execute transfer: $e'));
    }
  }
}
