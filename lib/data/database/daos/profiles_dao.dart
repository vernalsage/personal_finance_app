import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/profiles_table.dart';

part 'profiles_dao.g.dart';

/// DAO for Profiles table
@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  // CRUD Operations
  Future<Profile> createProfile(ProfilesCompanion entry) =>
      into(profiles).insertReturning(entry);

  Future<Profile> getProfile(int id) =>
      (select(profiles)..where((p) => p.id.equals(id))).getSingle();

  Future<List<Profile>> getAllProfiles({bool? isActive}) {
    final query = select(profiles);
    if (isActive != null) {
      query.where((p) => p.isActive.equals(isActive));
    }
    return query.get();
  }

  Future<Profile> updateProfile(ProfilesCompanion entry) =>
      update(profiles).writeReturning(entry).then((profiles) => profiles.first);

  Future<int> deleteProfile(int id) =>
      (delete(profiles)..where((p) => p.id.equals(id))).go();

  // Custom Queries
  Future<Profile?> getActiveProfile() {
    return (select(
      profiles,
    )..where((p) => p.isActive.equals(true))).getSingleOrNull();
  }

  Future<void> setActiveProfile(int profileId) {
    return transaction(() async {
      // Deactivate all profiles
      await (update(profiles)..where((p) => p.isActive.equals(true))).write(
        ProfilesCompanion(isActive: Value(false)),
      );

      // Activate specified profile
      await (update(profiles)..where((p) => p.id.equals(profileId))).write(
        ProfilesCompanion(isActive: Value(true)),
      );
    });
  }
}
