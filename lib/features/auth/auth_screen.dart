import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/config/app_config.dart';
import 'package:munch_or_dump/core/router/routes.dart';
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
    final theme = Theme.of(context);
    final showGoogle = AppConfig.googleSignInEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              _register ? 'Join Munch or Dump' : 'Welcome back',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.pushNamed(Routes.forgot),
                  child: const Text('Forgot password?'),
                ),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_register ? 'Create account' : 'Sign in'),
            ),
            if (showGoogle) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _googleSignIn,
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}
