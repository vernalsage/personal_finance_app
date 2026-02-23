import '../entities/profile.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Create a new profile
  Future<Result<Profile>> createProfile(Profile profile);

  /// Update an existing profile
  Future<Result<Profile>> updateProfile(Profile profile);

  /// Delete a profile
  Future<Result<void>> deleteProfile(int profileId);

  /// Get profile by ID
  Future<Result<Profile?>> getProfileById(int profileId);

  /// Get all profiles
  Future<Result<List<Profile>>> getAllProfiles({bool? isActive});

  /// Get active profile
  Future<Result<Profile?>> getActiveProfile();

  /// Set active profile
  Future<Result<Profile>> setActiveProfile(int profileId);
}
