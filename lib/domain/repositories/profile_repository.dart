import '../core/result.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Get profile by ID
  Future<Result<Profile?, Exception>> getProfileById(int id);

  /// Create a new profile
  Future<Result<Profile, Exception>> createProfile(Profile profile);

  /// Update an existing profile
  Future<Result<Profile, Exception>> updateProfile(Profile profile);
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.currency,
    this.email,
  });

  final int id;
  final String name;
  final String currency;
  final String? email;
}
