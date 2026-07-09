import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thrown when the user dismisses the Apple sign-in sheet — handled silently.
class AppleSignInCancelled implements Exception {
  const AppleSignInCancelled();
}

/// Runs the native Sign in with Apple flow and returns the identity token to
/// exchange at `/auth/apple`. Apple only surfaces the user's name on the very
/// first authorization, so it rides along for the backend to persist then.
class AppleAuthService {
  /// Interactive sign-in → identity token (+ full name when Apple provides
  /// one). Throws [AppleSignInCancelled] on cancel, or [ApiException] on any
  /// other failure. iOS-only — other platforms fail with a clean message.
  Future<({String identityToken, String? fullName})> signIn() async {
    if (!Platform.isIOS) {
      throw const ApiException('Apple sign-in isn’t available on this device.');
    }
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppleSignInCancelled();
      }
      throw ApiException(
        e.message.isEmpty ? 'Apple sign-in failed.' : e.message,
      );
    }
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const ApiException('Apple sign-in failed — no token returned.');
    }
    final fullName = <String?>[
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return (
      identityToken: identityToken,
      fullName: fullName.isEmpty ? null : fullName,
    );
  }
}

final appleAuthServiceProvider = Provider<AppleAuthService>(
  (ref) => AppleAuthService(),
);
