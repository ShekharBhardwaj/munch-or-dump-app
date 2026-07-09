import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/features/onboarding/personalization_options.dart';

void main() {
  group('labelForValue', () {
    test('maps a known code to its human label', () {
      expect(labelForValue('gluten_free', dietaryOptions), 'Gluten-free');
      expect(labelForValue('weight_loss', goalOptions), 'Weight loss');
      expect(labelForValue('parent', personaOptions), 'A parent / my family');
      expect(
        labelForValue('high_cholesterol', conditionOptions),
        'High cholesterol',
      );
    });

    test('humanizes an unknown code instead of showing the raw value', () {
      expect(labelForValue('seed_oils', dietaryOptions), 'Seed oils');
    });

    test('empty value passes through', () {
      expect(labelForValue('', goalOptions), '');
    });
  });

  test('labelsForValues maps a whole list', () {
    expect(
      labelsForValues(<String>['vegan', 'dairy_free'], dietaryOptions),
      <String>['Vegan', 'Dairy-free'],
    );
    expect(labelsForValues(const <String>[], goalOptions), <String>[]);
  });
}
