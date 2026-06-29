import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/app.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Bypasses secure storage / network in tests by resolving straight to
/// signed-out.
class _SignedOutAuthController extends AuthController {
  @override
  Future<User?> build() async => null;
}

Widget _app() => ProviderScope(
  overrides: <Override>[
    authControllerProvider.overrideWith(_SignedOutAuthController.new),
  ],
  child: const MunchOrDumpApp(),
);

void main() {
  testWidgets('app boots to the home screen when signed out', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Munch or Dump'), findsOneWidget);
    expect(find.text('Scan a product'), findsOneWidget);
  });

  testWidgets('account icon opens sign-in when signed out', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    // Google sign-in is gated: hidden until a server client ID is configured.
    expect(find.text('Continue with Google'), findsNothing);
  });
}
