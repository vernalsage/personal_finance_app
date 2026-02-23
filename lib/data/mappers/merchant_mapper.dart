import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/merchant.dart' as domain;

/// Extension methods to map between Drift Merchant and Domain Merchant
extension MerchantMapper on Merchant {
  /// Convert Drift Merchant to Domain Merchant
  domain.Merchant toEntity() {
    return domain.Merchant(
      id: id,
      profileId: profileId,
      name: name,
      normalizedName: normalizedName,
      lastSeen: lastSeen,
      categoryId: categoryId,
    );
  }
}

/// Extension methods to map from Domain Merchant to Drift objects
extension DomainMerchantMapper on domain.Merchant {
  /// Convert Domain Merchant to Drift MerchantsCompanion for inserts
  MerchantsCompanion toCompanion() {
    return MerchantsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      name: Value(name),
      normalizedName: Value(normalizedName),
      lastSeen: Value(lastSeen),
      categoryId: categoryId != null
          ? Value(categoryId!)
          : const Value.absent(),
    );
  }

  /// Convert Domain Merchant to Drift MerchantsCompanion for updates
  MerchantsCompanion toUpdateCompanion() {
    return MerchantsCompanion(
      name: Value(name),
      normalizedName: Value(normalizedName),
      lastSeen: Value(lastSeen),
      categoryId: categoryId != null
          ? Value(categoryId!)
          : const Value.absent(),
    );
  }
}
