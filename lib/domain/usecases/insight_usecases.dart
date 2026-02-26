import '../repositories/itransaction_repository.dart';
import '../core/result.dart';

/// Use case to get expense breakdown by category for a period
class GetExpenseBreakdownUseCase {
  final ITransactionRepository _repository;

  GetExpenseBreakdownUseCase(this._repository);

  Future<Result<Map<String, int>, Exception>> call({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final transactionsResult = await _repository.getTransactionsWithDetails(
        profileId: profileId,
        startDate: startDate,
        endDate: endDate,
        type: 'debit',
      );

      if (transactionsResult.isFailure) return Failure(transactionsResult.failureData!);

      final breakdown = <String, int>{};
      for (final t in transactionsResult.successData!) {
        final categoryName = t.category?.name ?? 'Other';
        breakdown[categoryName] = (breakdown[categoryName] ?? 0) + t.transaction.amountMinor.abs();
      }

      return Success(breakdown);
    } catch (e) {
      return Failure(Exception('Failed to get expense breakdown: $e'));
    }
  }
}

/// Use case to get weekly spending pattern
class GetWeeklySpendingUseCase {
  final ITransactionRepository _repository;

  GetWeeklySpendingUseCase(this._repository);

  Future<Result<List<int>, Exception>> call({
    required int profileId,
    required DateTime endDate,
  }) async {
    try {
      final startDate = endDate.subtract(const Duration(days: 6));
      final transactionsResult = await _repository.getTransactions(
        profileId: profileId,
        startDate: startDate,
        endDate: endDate,
        type: 'debit',
      );

      if (transactionsResult.isFailure) return Failure(transactionsResult.failureData!);

      // Initialize list for 7 days (index 0 is startDate)
      final dailySpending = List.filled(7, 0);
      
      for (final t in transactionsResult.successData!) {
        final diff = t.timestamp.difference(startDate).inDays;
        if (diff >= 0 && diff < 7) {
          dailySpending[diff] += t.amountMinor.abs();
        }
      }

      return Success(dailySpending);
    } catch (e) {
      return Failure(Exception('Failed to get weekly spending: $e'));
    }
  }
}
