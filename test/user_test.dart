import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses the /auth/me shape with a nested profile', () {
      final user = User.fromJson(<String, dynamic>{
        'id': 'u1',
        'email': 'a@b.com',
        'email_verified': true,
        'plan': 'premium',
        'is_admin': true,
        'tier': 'fresh_eyes',
        'approved_product_count': 3,
        'achievements': <String>['first_scan'],
        'profile': <String, dynamic>{
          'persona': 'myself',
          'goals': <String>['clean_eating'],
          'dietary': <String>['vegan'],
          'conditions': <String>[],
          'context': 'no seed oils',
        },
      });

      expect(user.id, 'u1');
      expect(user.emailVerified, isTrue);
      expect(user.isAdmin, isTrue);
      expect(user.isPremium, isTrue);
      expect(user.approvedProductCount, 3);
      expect(user.profile?.persona, 'myself');
      expect(user.profile?.dietaryList, <String>['vegan']);
    });

    test('applies defaults for a minimal payload', () {
      final user = User.fromJson(<String, dynamic>{
        'id': 'x',
        'email': 'e@e.com',
      });
      expect(user.plan, 'free');
      expect(user.isPremium, isFalse);
      expect(user.profile, isNull);
      expect(user.achievements, isEmpty);
    });
  });

  group('needsOnboarding', () {
    User withProfile(Map<String, dynamic>? profile) {
      final json = <String, dynamic>{'id': 'i', 'email': 'e@e.com'};
      if (profile != null) json['profile'] = profile;
      return User.fromJson(json);
    }

    test('true when there is no profile', () {
      expect(withProfile(null).needsOnboarding, isTrue);
    });

    test('true when neither persona nor goals are set', () {
      expect(
        withProfile(<String, dynamic>{'dietary': <String>[]}).needsOnboarding,
        isTrue,
      );
    });

    test('true when dietary is absent (predates the dietary step)', () {
      expect(
        withProfile(<String, dynamic>{
          'persona': 'myself',
          'goals': <String>['clean_eating'],
        }).needsOnboarding,
        isTrue,
      );
    });

    test('false once persona/goals and dietary are present', () {
      expect(
        withProfile(<String, dynamic>{
          'persona': 'myself',
          'goals': <String>['clean_eating'],
          'dietary': <String>['vegan'],
        }).needsOnboarding,
        isFalse,
      );
    });
  });
}
