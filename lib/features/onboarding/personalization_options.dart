/// Personalization options for onboarding/profile. Values MUST match the API's
/// allowed sets in `functions/auth/handler.py` (the backend validates and
/// rejects anything else).
library;

typedef LabeledOption = ({String value, String label});

/// `persona` — single select.
const List<LabeledOption> personaOptions = <LabeledOption>[
  (value: 'myself', label: 'Just me'),
  (value: 'parent', label: 'A parent / my family'),
  (value: 'advisor', label: 'A coach or advisor'),
];

/// `goals` — multi select.
const List<LabeledOption> goalOptions = <LabeledOption>[
  (value: 'weight_loss', label: 'Weight loss'),
  (value: 'clean_eating', label: 'Clean eating'),
  (value: 'high_protein', label: 'High protein'),
  (value: 'managing_condition', label: 'Managing a condition'),
];

/// `dietary` — multi select.
const List<LabeledOption> dietaryOptions = <LabeledOption>[
  (value: 'gluten_free', label: 'Gluten-free'),
  (value: 'dairy_free', label: 'Dairy-free'),
  (value: 'vegan', label: 'Vegan'),
  (value: 'vegetarian', label: 'Vegetarian'),
  (value: 'nut_free', label: 'Nut-free'),
  (value: 'low_sodium', label: 'Low sodium'),
  (value: 'low_sugar', label: 'Low sugar'),
  (value: 'keto', label: 'Keto'),
  (value: 'halal', label: 'Halal'),
  (value: 'kosher', label: 'Kosher'),
];

/// `conditions` — multi select.
const List<LabeledOption> conditionOptions = <LabeledOption>[
  (value: 'diabetes', label: 'Diabetes'),
  (value: 'hypertension', label: 'Hypertension'),
  (value: 'high_cholesterol', label: 'High cholesterol'),
  (value: 'ibs', label: 'IBS'),
  (value: 'celiac', label: 'Celiac'),
  (value: 'kidney_disease', label: 'Kidney disease'),
  (value: 'pregnancy', label: 'Pregnancy'),
];

/// Max length of the freeform personal note (`context`), per the API.
const int maxContextChars = 150;

/// The human label for a stored [value] within [options], falling back to a
/// humanized form of the raw code (e.g. `high_cholesterol` → "High cholesterol")
/// so the UI never shows machine values.
String labelForValue(String value, List<LabeledOption> options) {
  for (final option in options) {
    if (option.value == value) return option.label;
  }
  if (value.isEmpty) return value;
  final spaced = value.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// [labelForValue] mapped over a list of stored values.
List<String> labelsForValues(
  List<String> values,
  List<LabeledOption> options,
) => <String>[for (final v in values) labelForValue(v, options)];
