import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/config/app_config.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/auth_navigation.dart';
import 'package:munch_or_dump/features/auth/google_auth_service.dart';

/// Sign in / create account against the Munch or Dump API (email + password).
/// Google sign-in is shown only when a server client ID is configured (Phase 1
/// ships the gate; the native flow is wired once the iOS client ID exists).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return 'Enter a valid email.';
    if (_password.text.isEmpty) return 'Enter your password.';
    if (_register && _password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _email.text.trim();
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_register) {
        await auth.register(email, _password.text);
        if (!mounted) return;
        unawaited(context.pushNamed(Routes.verify, extra: email));
      } else {
        final user = await auth.signInWithEmail(email, _password.text);
        if (!mounted) return;
        goAfterAuth(context, user);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      // Unverified account → send them to enter the emailed code.
      if (e.data?['requires_verification'] == true) {
        unawaited(context.pushNamed(Routes.verify, extra: email));
        return;
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _register = !_register;
      _error = null;
    });
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final idToken = await ref.read(googleAuthServiceProvider).signIn();
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle(idToken);
      if (!mounted) return;
      goAfterAuth(context, user);
    } on GoogleSignInCancelled {
      // User dismissed the Google sheet — no error.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showGoogle = AppConfig.googleSignInEnabled;

    return FormScaffold(
      eyebrow: 'Munch or Dump',
      titleDark: _register ? 'Create your' : 'Welcome',
      titleMuted: _register ? 'account.' : 'back.',
      subtitle: _register
          ? 'Scan anything, get a straight verdict, and save the products you '
                'care about.'
          : 'Sign in to pick up where you left off.',
      children: <Widget>[
        LabeledField(
          label: 'Email',
          child: TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Password',
          child: TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: '••••••••'),
          ),
        ),
        if (!_register)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : () => context.pushNamed(Routes.forgot),
              child: const Text('Forgot password?'),
            ),
          ),
        if (_error != null) FormMessage(_error!),
        const SizedBox(height: 20),
        BlackCtaButton(
          label: _register ? 'Create account' : 'Sign in',
          expand: true,
          busy: _busy,
          trailingIcon: null,
          onTap: _submit,
        ),
        if (showGoogle) ...<Widget>[
          const SizedBox(height: 12),
          _GoogleButton(onTap: _busy ? null : _googleSignIn),
        ],
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _toggleMode,
            child: Text(
              _register
                  ? 'Already have an account? Sign in'
                  : 'New here? Create an account',
            ),
          ),
        ),
        const SizedBox(height: 4),
        const _TermsLine(),
      ],
    );
  }
}

/// Full-width outlined pill for the Google sign-in secondary action.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.account_circle_outlined, size: 18),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.inkPrimary,
        backgroundColor: AppColors.surface,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.hairline),
        ),
      ),
    );
  }
}

/// Acceptance-by-action line with tappable Terms + Privacy links — also the way
/// a logged-out user reaches the legal docs.
class _TermsLine extends StatelessWidget {
  const _TermsLine();

  @override
  Widget build(BuildContext context) {
    final link = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.brand,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          const TextSpan(text: 'By continuing you agree to our '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => context.pushNamed(Routes.legal),
              child: Text('Terms', style: link),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => context.pushNamed(Routes.privacy),
              child: Text('Privacy Policy', style: link),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
    );
  }
}
