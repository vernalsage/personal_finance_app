import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/account.dart' as domain;

/// Extension methods to map between Drift Account and Domain Account
extension AccountMapper on Account {
  /// Convert Drift Account to Domain Account
  domain.Account toEntity() {
    return domain.Account(
      id: id,
      profileId: profileId,
      name: name,
      type: type,
      balanceMinor: balanceMinor,
      currency: currency,
      isActive: isActive,
      description: description,
    );
  }
}

/// Extension methods to map from Domain Account to Drift objects
extension DomainAccountMapper on domain.Account {
  /// Convert Domain Account to Drift AccountsCompanion for inserts
  AccountsCompanion toCompanion() {
    return AccountsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      name: Value(name),
      type: Value(type),
      balanceMinor: Value(balanceMinor),
      currency: Value(currency),
      isActive: Value(isActive),
      description: description != null
          ? Value(description!)
          : const Value.absent(),
    );
  }

  /// Convert Domain Account to Drift AccountsCompanion for updates
  AccountsCompanion toUpdateCompanion() {
    return AccountsCompanion(
      name: Value(name),
      type: Value(type),
      balanceMinor: Value(balanceMinor),
      currency: Value(currency),
      isActive: Value(isActive),
      description: description != null
          ? Value(description!)
          : const Value.absent(),
    );
  }
}
