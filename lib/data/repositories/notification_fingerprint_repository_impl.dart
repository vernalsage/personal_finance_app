import '../../domain/core/result.dart';
import '../../domain/repositories/inotification_fingerprint_repository.dart';
import '../database/daos/notification_fingerprints_dao.dart';
import '../database/app_database_simple.dart';
import 'package:drift/drift.dart';

class NotificationFingerprintRepositoryImpl implements INotificationFingerprintRepository {
  final NotificationFingerprintsDao _dao;

  NotificationFingerprintRepositoryImpl(this._dao);

  @override
  Future<Result<bool, Exception>> exists(String fingerprint) async {
    try {
      final exists = await _dao.exists(fingerprint);
      return Success(exists);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> markAsProcessed(String fingerprint, {int? transactionId}) async {
    try {
      await _dao.insertFingerprint(
        NotificationFingerprintsCompanion(
          fingerprint: Value(fingerprint),
          transactionId: transactionId != null ? Value(transactionId) : const Value.absent(),
          processedAt: Value(DateTime.now()),
        ),
      );
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> cleanup(DateTime before) async {
    try {
      await _dao.deleteOlderThan(before);
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
