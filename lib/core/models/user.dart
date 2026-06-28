import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// The authenticated user, as returned by `/auth/me` and the auth endpoints.
@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.email,
    this.plan,
    this.persona,
    this.goals,
    this.dietary,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  final String id;
  final String email;
  final String? plan;
  final String? persona;
  final List<String>? goals;
  final List<String>? dietary;

  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// True once onboarding has captured the personalization profile.
  bool get hasCompletedOnboarding =>
      persona != null && (goals?.isNotEmpty ?? false);
}
