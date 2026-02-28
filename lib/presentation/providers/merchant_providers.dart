import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/repository_providers.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/transaction_with_details.dart';

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
final merchantTransactionsProvider = FutureProvider.family<List<TransactionWithDetails>, int>((ref, merchantId) async {
  final repository = ref.read(transactionRepositoryProvider);
  final result = await repository.getTransactionsWithDetails(
    profileId: 1,
  );
  
  if (result.isFailure) {
    throw result.failureData!;
  }
  
  return result.successData!.where((t) => t.merchant?.id == merchantId).toList();
});
