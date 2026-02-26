import '../database/daos/merchants_dao.dart';
import '../mappers/merchant_mapper.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/merchant.dart' as domain;

/// Implementation of MerchantRepository using Drift DAO
class MerchantRepositoryImpl implements MerchantRepository {
  final MerchantsDao _merchantsDao;

  MerchantRepositoryImpl(this._merchantsDao);

  @override
  Future<Result<domain.Merchant, Exception>> createMerchant(
    domain.Merchant merchant,
  ) async {
    try {
      final companion = merchant.toCompanion();
      final createdMerchant = await _merchantsDao.createMerchant(companion);
      return Success(createdMerchant.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create merchant: $e'));
    }
  }

  @override
  Future<Result<domain.Merchant, Exception>> updateMerchant(
    domain.Merchant merchant,
  ) async {
    try {
      final companion = merchant.toUpdateCompanion();
      final updatedMerchant = await _merchantsDao.updateMerchant(companion);
      return Success(updatedMerchant.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update merchant: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteMerchant(int merchantId) async {
    try {
      await _merchantsDao.deleteMerchant(merchantId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete merchant: $e'));
    }
  }

  @override
  Future<Result<domain.Merchant?, Exception>> getMerchantById(int merchantId) async {
    try {
      final merchant = await _merchantsDao.getMerchant(merchantId);
      return Success(merchant?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get merchant by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Merchant>, Exception>> getMerchants(int profileId) async {
    try {
      final merchants = await _merchantsDao.getAllMerchants(
        profileId: profileId,
      );
      final domainMerchants = merchants
          .map((merchant) => merchant.toEntity())
          .toList();
      return Success(domainMerchants);
    } catch (e) {
      return Failure(Exception('Failed to get merchants: $e'));
    }
  }

  @override
  Future<Result<domain.Merchant?, Exception>> getMerchantByName(
    int profileId,
    String name,
  ) async {
    try {
      final merchant = await _merchantsDao.getMerchantByName(
        profileId,
        name,
      );
      return Success(merchant?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get merchant by name: $e'));
    }
  }

  @override
  String normalizeMerchantName(String rawName) {
    if (rawName.isEmpty) return 'Unknown';
    
    // 1. Convert to lowercase
    String normalized = rawName.toLowerCase();
    
    // 2. Remove common business suffixes
    final suffixes = [
      ' ltd', ' limited', ' inc', ' incorporated', ' corp', ' corporation', 
      ' plc', ' p.l.c', ' nig', ' nig.', ' gh', ' gh.', ' safaricom', ' m-pesa'
    ];
    for (final suffix in suffixes) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
      }
    }
    
    // 3. Remove terminal codes and transaction prefixes (e.g. POS* BOLT * 1234)
    normalized = normalized
        .replaceAll(RegExp(r'pos\s*\*?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\*?\s*\d{4,}', caseSensitive: false), '') // Numbers like 1234
        .replaceAll(RegExp(r'\*+\s*', caseSensitive: false), '')
        .trim();
        
    // 4. Proper Case (Capitalize each word for display)
    if (normalized.isEmpty) return 'Unknown';
    return normalized.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Future<Result<domain.Merchant, Exception>> getOrCreateMerchant(
    int profileId,
    String rawName,
    String normalizedName, {
    int? categoryId,
  }) async {
    try {
      final existingResult = await getMerchantByName(profileId, normalizedName);
      if (existingResult.isSuccess && existingResult.successData != null) {
        return Success(existingResult.successData!);
      }

      final newMerchant = domain.Merchant(
        id: 0,
        profileId: profileId,
        name: rawName,
        normalizedName: normalizedName,
        lastSeen: DateTime.now(),
        categoryId: categoryId,
      );

      return await createMerchant(newMerchant);
    } catch (e) {
      return Failure(Exception('Failed to get or create merchant: $e'));
    }
  }
}
