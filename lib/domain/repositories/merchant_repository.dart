import '../entities/merchant.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for merchant operations
abstract class MerchantRepository {
  /// Create a new merchant (or get existing one)
  Future<Result<Merchant>> getOrCreateMerchant(
    int profileId,
    String name,
    String normalizedName, {
    int? categoryId,
  });

  /// Update merchant
  Future<Result<Merchant>> updateMerchant(Merchant merchant);

  /// Update merchant last seen timestamp
  Future<Result<Merchant>> updateLastSeen(int merchantId);

  /// Get merchant by ID
  Future<Result<Merchant?>> getMerchantById(int merchantId);

  /// Get merchant by normalized name and profile
  Future<Result<Merchant?>> getMerchantByNormalizedName(
    int profileId,
    String normalizedName,
  );

  /// Get merchants for a profile
  Future<Result<List<Merchant>>> getMerchants(
    int profileId, {
    int? categoryId,
    DateTime? lastSeenSince,
    int? limit,
    int? offset,
  });

  /// Get recently seen merchants
  Future<Result<List<Merchant>>> getRecentlySeenMerchants(
    int profileId, {
    int days = 30,
    int? limit,
  });
}
