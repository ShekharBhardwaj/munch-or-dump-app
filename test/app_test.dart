import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/app.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bypasses secure storage / network in tests by resolving straight to
/// signed-out.
class _SignedOutAuthController extends AuthController {
  @override
  Future<User?> build() async => null;
}

Future<Widget> _app() async {
  // The cart hydrates synchronously from the prefs preloaded in main() — mirror
  // that here with a mock-backed instance.
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: <Override>[
      sharedPrefsProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith(_SignedOutAuthController.new),
      // No network for the home "recently analyzed" feed.
      recentProductsProvider.overrideWith((ref) async => <ProductListItem>[]),
    ],
    child: const MunchOrDumpApp(),
  );
}

void main() {
  testWidgets('app boots to the home screen when signed out', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('INGREDIENT INTELLIGENCE'), findsOneWidget);
    expect(find.text('Analyze a product'), findsOneWidget);
  });

  testWidgets('You tab offers sign-in when signed out', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    // Bottom-bar "You" tab → the signed-out invitation.
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to Munch or Dump'), findsOneWidget);

    // Its "Sign in" CTA opens the login screen.
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // The two-tone headline "Welcome back." is rich text; assert on the
    // login-only affordances instead.
    expect(find.text('New here? Create an account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    // Google sign-in is gated: hidden until a server client ID is configured.
    expect(find.text('Continue with Google'), findsNothing);
  });
}
