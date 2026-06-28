import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/app.dart';

void main() {
  testWidgets('app boots to the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MunchOrDumpApp()));
    await tester.pumpAndSettle();

    expect(find.text('Munch or Dump'), findsOneWidget);
    expect(find.text('Scan a product'), findsOneWidget);
  });
}
