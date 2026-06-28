import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/router/routes.dart';

/// Where to land after a successful sign-in: onboarding if the profile isn't
/// set up yet, otherwise home. Uses `go` so the auth stack is cleared.
void goAfterAuth(BuildContext context, User user) {
  if (user.needsOnboarding) {
    context.goNamed(Routes.onboarding);
  } else {
    context.goNamed(Routes.home);
  }
}
