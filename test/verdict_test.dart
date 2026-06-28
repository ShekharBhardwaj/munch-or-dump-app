import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/verdict.dart';

void main() {
  group('Verdict.fromApi', () {
    test('parses every canonical API token', () {
      for (final verdict in Verdict.values) {
        expect(Verdict.fromApi(verdict.apiValue), verdict);
      }
    });

    test('tolerates case and surrounding whitespace', () {
      expect(Verdict.fromApi('  munch '), Verdict.munch);
      expect(Verdict.fromApi('Dump'), Verdict.dump);
    });

    test('maps ULTRA* synonyms to engineered', () {
      expect(Verdict.fromApi('ULTRA-PROCESSED'), Verdict.engineered);
    });

    test('falls back to okay on null/unknown input', () {
      expect(Verdict.fromApi(null), Verdict.okay);
      expect(Verdict.fromApi('???'), Verdict.okay);
    });
  });

  test('isBad flags the avoid-these verdicts', () {
    expect(Verdict.dump.isBad, isTrue);
    expect(Verdict.engineered.isBad, isTrue);
    expect(Verdict.bullshit.isBad, isTrue);
    expect(Verdict.munch.isBad, isFalse);
    expect(Verdict.okay.isBad, isFalse);
    expect(Verdict.treat.isBad, isFalse);
  });
}
