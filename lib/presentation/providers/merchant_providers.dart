import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/repository_providers.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/itransaction_repository.dart';

/// Provider for managing the list of merchants
final merchantsProvider = AsyncNotifierProvider<MerchantsNotifier, List<Merchant>>(
  MerchantsNotifier.new,
);

class MerchantsNotifier extends AsyncNotifier<List<Merchant>> {
  @override
  Future<List<Merchant>> build() async {
    return _fetchMerchants();
  }

  Future<List<Merchant>> _fetchMerchants() async {
    final repository = ref.read(merchantRepositoryProvider);
    final result = await repository.getMerchants(1); // Default profile

    if (result.isFailure) {
      throw result.failureData!;
    }

    return result.successData!;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMerchants());
  }
}

/// Provider for merchant-specific transactions and insights
final merchantTransactionsProvider = FutureProvider.family<List<TransactionWithJoinedDetails>, int>((ref, merchantId) async {
  final repository = ref.read(transactionRepositoryProvider);
  final result = await repository.getTransactionsWithDetails(
    profileId: 1,
  );
  
  if (result.isFailure) {
    throw result.failureData!;
  }
  
  // Filter by merchantId manually for now if the DAO doesn't support it directly in getTransactionsWithDetails
  // (Assuming TransactionsDao.getTransactionsWithDetails supports filtering by merchantId, which I should check)
  return result.successData!.where((t) => t.merchant?.id == merchantId).toList();
});
