import '../entities/merchant.dart';
import '../core/result.dart';

/// Repository interface for merchant operations
abstract class MerchantRepository {
  /// Create a new merchant
  Future<Result<Merchant, Exception>> createMerchant(Merchant merchant);

  /// Update an existing merchant
  Future<Result<Merchant, Exception>> updateMerchant(Merchant merchant);

  /// Delete a merchant
  Future<Result<void, Exception>> deleteMerchant(int merchantId);

  /// Get merchant by ID
  Future<Result<Merchant?, Exception>> getMerchantById(int merchantId);

  /// Get merchants for a profile
  Future<Result<List<Merchant>, Exception>> getMerchants(int profileId);

  /// Get merchant by name
  Future<Result<Merchant?, Exception>> getMerchantByName(
    int profileId,
    String name,
  );

  /// Normalize merchant name
  String normalizeMerchantName(String rawName);

  /// Get or create a merchant securely
  Future<Result<Merchant, Exception>> getOrCreateMerchant(
    int profileId,
    String rawName,
    String normalizedName, {
    int? categoryId,
  });
}
