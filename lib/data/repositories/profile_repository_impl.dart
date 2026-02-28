import '../database/daos/profiles_dao.dart';
import '../../domain/repositories/profile_repository.dart' as domain;
import '../../domain/core/result.dart';
import 'package:drift/drift.dart';
import '../database/app_database_simple.dart' as db;

/// Implementation of ProfileRepository using Drift DAO
class ProfileRepositoryImpl implements domain.ProfileRepository {
  final ProfilesDao _profilesDao;

  ProfileRepositoryImpl(this._profilesDao);

  @override
  Future<Result<domain.Profile?, Exception>> getProfileById(int id) async {
    try {
      final profile = await _profilesDao.getProfile(id);
      return Success(_mapToDomain(profile));
    } catch (e) {
      return Failure(Exception('Failed to get profile: $e'));
    }
  }

  @override
  Future<Result<domain.Profile, Exception>> createProfile(domain.Profile profile) async {
    try {
      final companion = db.ProfilesCompanion.insert(
        name: profile.name,
        currency: profile.currency,
      );
      final created = await _profilesDao.createProfile(companion);
      return Success(_mapToDomain(created));
    } catch (e) {
      return Failure(Exception('Failed to create profile: $e'));
    }
  }

  @override
  Future<Result<domain.Profile, Exception>> updateProfile(domain.Profile profile) async {
    try {
      final companion = db.ProfilesCompanion(
        id: Value(profile.id),
        name: Value(profile.name),
        currency: Value(profile.currency),
        updatedAt: Value(DateTime.now()),
      );
      final updated = await _profilesDao.updateProfile(companion);
      return Success(_mapToDomain(updated));
    } catch (e) {
      return Failure(Exception('Failed to update profile: $e'));
    }
  }

  domain.Profile _mapToDomain(db.Profile profile) {
    return domain.Profile(
      id: profile.id,
      name: profile.name,
      currency: profile.currency,
    );
  }
}
