import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/notification_fingerprints_table.dart';

part 'notification_fingerprints_dao.g.dart';

@DriftAccessor(tables: [NotificationFingerprints])
class NotificationFingerprintsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationFingerprintsDaoMixin {
  NotificationFingerprintsDao(super.db);

  /// Check if a fingerprint has already been processed
  Future<bool> exists(String fingerprint) async {
    final query = select(notificationFingerprints)
      ..where((t) => t.fingerprint.equals(fingerprint));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Store a new fingerprint
  Future<int> insertFingerprint(NotificationFingerprintsCompanion entry) {
    return into(notificationFingerprints).insert(entry);
  }

  /// Delete old fingerprints (cleanup)
  Future<int> deleteOlderThan(DateTime date) {
    return (delete(notificationFingerprints)
          ..where((t) => t.processedAt.isSmallerThanValue(date)))
        .go();
  }
}
