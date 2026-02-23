import '../../data/models/profile_model.dart';

/// Profile entity representing a user profile
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.currency,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String currency;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create from model
  factory Profile.fromModel(ProfileModel model) {
    return Profile(
      id: model.id,
      name: model.name,
      currency: model.currency,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// Convert to model
  ProfileModel toModel() {
    return ProfileModel(
      id: id,
      name: name,
      currency: currency,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Check if profile is active
  bool get isInactive => !isActive;

  /// Get currency symbol
  String get currencySymbol {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }
}
