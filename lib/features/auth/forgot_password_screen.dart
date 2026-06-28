import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Two steps in one screen: request a reset code, then set a new password with
/// it. On success we pop back to the sign-in screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email);
      if (mounted) setState(() => _codeSent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (code.length < 6 || _password.text.length < 6) {
      setState(
        () =>
            _error = 'Enter the 6-digit code and a password of 6+ characters.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(email, code, _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated — sign in.')),
      );
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              _codeSent ? 'Enter your code' : 'Forgot your password?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'If that email exists, a 6-digit reset code is on its way.'
                  : 'Enter your email and we’ll send a reset code.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              enabled: !_busy && !_codeSent,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            if (_codeSent) ...<Widget>[
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: '6-digit code',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : (_codeSent ? _resetPassword : _requestCode),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_codeSent ? 'Update password' : 'Send reset code'),
            ),
          ],
        ),
      ),
    );
  }
}
