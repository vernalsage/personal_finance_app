import '../database/daos/merchants_dao.dart';
import '../database/app_database_simple.dart';
import '../mappers/merchant_mapper.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/merchant.dart' as domain;
import 'package:drift/drift.dart';

/// Implementation of MerchantRepository using Drift DAO
class MerchantRepositoryImpl implements MerchantRepository {
  final MerchantsDao _merchantsDao;

  MerchantRepositoryImpl(this._merchantsDao);

  @override
  Future<Result<domain.Merchant>> getOrCreateMerchant(
    int profileId,
    String name,
    String normalizedName, {
    int? categoryId,
  }) async {
    try {
      // First try to find existing merchant by normalized name
      final existingMerchant = await _merchantsDao.getMerchantByName(
        profileId,
        normalizedName,
      );
      if (existingMerchant != null) {
        // Update last seen timestamp
        await _merchantsDao.updateLastSeen(existingMerchant.id);
        return Result.success(existingMerchant.toEntity());
      }

      // Create new merchant if not found
      final companion = MerchantsCompanion.insert(
        profileId: profileId,
        name: name,
        normalizedName: normalizedName,
        categoryId: categoryId != null
            ? Value(categoryId)
            : const Value.absent(),
        lastSeen: DateTime.now(),
      );
      final createdMerchant = await _merchantsDao.createMerchant(companion);
      return Result.success(createdMerchant.toEntity());
    } catch (e) {
      return Result.failure('Failed to get or create merchant: $e');
    }
  }

  @override
  Future<Result<domain.Merchant>> updateMerchant(
    domain.Merchant merchant,
  ) async {
    try {
      final companion = merchant.toUpdateCompanion();
      final updatedMerchant = await _merchantsDao.updateMerchant(companion);
      return Result.success(updatedMerchant.toEntity());
    } catch (e) {
      return Result.failure('Failed to update merchant: $e');
    }
  }

  @override
  Future<Result<domain.Merchant>> updateLastSeen(int merchantId) async {
    try {
      await _merchantsDao.updateLastSeen(merchantId);
      // Return the updated merchant
      final merchant = await _merchantsDao.getMerchant(merchantId);
      return Result.success(merchant.toEntity());
    } catch (e) {
      return Result.failure('Failed to update last seen: $e');
    }
  }

  @override
  Future<Result<domain.Merchant?>> getMerchantById(int merchantId) async {
    try {
      final merchant = await _merchantsDao.getMerchant(merchantId);
      return Result.success(merchant.toEntity());
    } catch (e) {
      return Result.failure('Failed to get merchant by ID: $e');
    }
  }

  @override
  Future<Result<domain.Merchant?>> getMerchantByNormalizedName(
    int profileId,
    String normalizedName,
  ) async {
    try {
      final merchant = await _merchantsDao.getMerchantByName(
        profileId,
        normalizedName,
      );
      return Result.success(merchant?.toEntity());
    } catch (e) {
      return Result.failure('Failed to get merchant by normalized name: $e');
    }
  }

  @override
  Future<Result<List<domain.Merchant>>> getMerchants(
    int profileId, {
    int? categoryId,
    DateTime? lastSeenSince,
    int? limit,
    int? offset,
  }) async {
    try {
      final merchants = await _merchantsDao.getAllMerchants(
        profileId: profileId,
      );
      final domainMerchants = merchants
          .map((merchant) => merchant.toEntity())
          .toList();
      return Result.success(domainMerchants);
    } catch (e) {
      return Result.failure('Failed to get merchants: $e');
    }
  }

  @override
  Future<Result<List<domain.Merchant>>> getRecentlySeenMerchants(
    int profileId, {
    int days = 30,
    int? limit,
  }) async {
    try {
      final merchants = await _merchantsDao.getAllMerchants(
        profileId: profileId,
      );
      final domainMerchants = merchants
          .map((merchant) => merchant.toEntity())
          .toList();
      return Result.success(domainMerchants);
    } catch (e) {
      return Result.failure('Failed to get recently seen merchants: $e');
    }
  }
}
