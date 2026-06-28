/// Request payload for `PATCH /auth/profile`. Values must come from the API's
/// allowed sets (see `personalization_options.dart`); the backend rejects others.
class ProfileUpdate {
  const ProfileUpdate({
    this.persona,
    this.goals = const <String>[],
    this.dietary = const <String>[],
    this.conditions = const <String>[],
    this.context = '',
  });

  final String? persona;
  final List<String> goals;
  final List<String> dietary;
  final List<String> conditions;
  final String context;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'persona': persona,
    'goals': goals,
    'dietary': dietary,
    'conditions': conditions,
    'context': context,
  };
}
