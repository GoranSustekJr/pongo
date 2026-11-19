import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// The signed in user's account details.
@freezed
abstract class UserProfile with _$UserProfile {
  /// Creates a profile.
  const factory UserProfile({
    required String email,
    required String name,

    /// URL of the profile picture.
    required String picture,

    /// Whether the email is a private relay address.
    required bool hiddenAuth,
  }) = _UserProfile;

  /// Creates a profile from the API's JSON.
  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    email: map['email'] as String? ?? '',
    name: map['name'] as String? ?? '',
    picture: map['picture'] as String? ?? '',
    hiddenAuth: map['hidden_auth'] as bool? ?? false,
  );
}
