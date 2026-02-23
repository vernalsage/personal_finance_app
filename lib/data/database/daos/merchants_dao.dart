import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/merchants_table.dart';

part 'merchants_dao.g.dart';

@DriftAccessor(tables: [Merchants])
class MerchantsDao extends DatabaseAccessor<AppDatabase>
    with _$MerchantsDaoMixin {
  MerchantsDao(super.db);

  Future<Merchant> createMerchant(MerchantsCompanion entry) =>
      into(merchants).insertReturning(entry);
  Future<Merchant> getMerchant(int id) =>
      (select(merchants)..where((m) => m.id.equals(id))).getSingle();
  Future<List<Merchant>> getAllMerchants({int? profileId}) {
    final query = select(merchants);
    if (profileId != null) query.where((m) => m.profileId.equals(profileId));
    return query.get();
  }

  Future<Merchant> updateMerchant(MerchantsCompanion entry) => update(
    merchants,
  ).writeReturning(entry).then((merchants) => merchants.first);
  Future<int> deleteMerchant(int id) =>
      (delete(merchants)..where((m) => m.id.equals(id))).go();

  Future<Merchant?> getMerchantByName(int profileId, String normalizedName) {
    return (select(merchants)..where(
          (m) =>
              m.profileId.equals(profileId) &
              m.normalizedName.equals(normalizedName),
        ))
        .getSingleOrNull();
  }

  Future<void> updateLastSeen(int merchantId) {
    return (update(merchants)..where((m) => m.id.equals(merchantId))).write(
      MerchantsCompanion(lastSeen: Value(DateTime.now())),
    );
  }
}
