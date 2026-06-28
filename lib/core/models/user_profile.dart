import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

/// The user's personalization profile, nested under `profile` in `/auth/me`.
/// Lists are nullable so we can distinguish "not set" from "empty" — the
/// onboarding trigger depends on `dietary` being absent (see [User.needsOnboarding]).
@JsonSerializable()
class UserProfile {
  const UserProfile({
    this.persona,
    this.goals,
    this.dietary,
    this.conditions,
    this.context,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  final String? persona;
  final List<String>? goals;
  final List<String>? dietary;
  final List<String>? conditions;
  final String? context;

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  List<String> get goalsList => goals ?? const <String>[];
  List<String> get dietaryList => dietary ?? const <String>[];
  List<String> get conditionsList => conditions ?? const <String>[];
}
