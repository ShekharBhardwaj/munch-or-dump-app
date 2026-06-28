import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/auth_navigation.dart';

/// Enter the 6-digit code emailed by `/auth/register`. On success the account is
/// verified and a session is minted.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  final _code = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (email.isEmpty || code.length < 6) {
      setState(() => _error = 'Enter your email and the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .completeVerification(email, code);
      if (!mounted) return;
      goAfterAuth(context, user);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).resendVerification(email);
      if (mounted) setState(() => _notice = 'A new code is on its way.');
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
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              'Check your inbox',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to verify your account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: (_) => _verify(),
              decoration: const InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            if (_notice != null)
              Text(
                _notice!,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _verify,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
