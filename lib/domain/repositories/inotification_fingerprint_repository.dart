import '../core/result.dart';

abstract class INotificationFingerprintRepository {
  Future<Result<bool, Exception>> exists(String fingerprint);
  Future<Result<void, Exception>> markAsProcessed(String fingerprint, {int? transactionId});
  Future<Result<void, Exception>> cleanup(DateTime before);
}
