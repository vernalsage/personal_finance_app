import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../../domain/repositories/iaccount_repository.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/merchant_repository_impl.dart';

/// Provider for Account Repository
final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(accountsDaoProvider));
});

/// Provider for Transaction Repository
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(transactionsDaoProvider));
});

/// Provider for Merchant Repository
final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepositoryImpl(ref.watch(merchantsDaoProvider));
});
