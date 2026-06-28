import 'package:json_annotation/json_annotation.dart';
import 'package:munch_or_dump/core/models/user_profile.dart';

part 'user.g.dart';

/// The authenticated user, as returned by `/auth/me`. (login/google/verify
/// return only a partial `{id, email, plan}` — the app always re-fetches the
/// full user from `/auth/me`, mirroring the web AuthContext.)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class User {
  const User({
    required this.id,
    required this.email,
    this.emailVerified = false,
    this.plan = 'free',
    this.isAdmin = false,
    this.profile,
    this.tier,
    this.approvedProductCount = 0,
    this.achievements = const <String>[],
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  final String id;
  final String email;
  final bool emailVerified;
  final String plan;
  final bool isAdmin;
  final UserProfile? profile;
  final String? tier;
  final int approvedProductCount;
  final List<String> achievements;

  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isPremium => plan != 'free';

  /// Mirrors the web AuthContext onboarding trigger: show onboarding when there
  /// is no profile, when neither persona nor goals are set, or when `dietary`
  /// was never captured (predates the dietary step).
  bool get needsOnboarding {
    final p = profile;
    if (p == null) return true;
    final noPersona = p.persona == null || p.persona!.isEmpty;
    final noGoals = (p.goals ?? const <String>[]).isEmpty;
    if (noPersona && noGoals) return true;
    if (p.dietary == null) return true;
    return false;
  }
}
