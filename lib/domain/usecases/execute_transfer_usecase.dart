import '../repositories/itransaction_repository.dart';
import '../core/result.dart';

/// Use case for executing atomic transfers between accounts
class ExecuteTransferUseCase {
  final ITransactionRepository _repository;

  ExecuteTransferUseCase(this._repository);

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
      // Use the repository's dedicated transfer method which is atomic in the DAO
      final result = await _repository.createTransfer(
        profileId: profileId ?? 1,
        fromAccountId: sourceAccountId,
        toAccountId: destinationAccountId,
        amountMinor: amountMinor,
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
